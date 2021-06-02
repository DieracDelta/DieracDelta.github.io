---
author:
  name: "Justin Restivo"
date: 2021-05-30
title: Writing a "hello world" Riscv Kernel with Nix in Rust
---

# Motivation

The purpose of this tutorial is to showcase two main things:

- How great `nix` can be for speeding up embedded development
- Writing a "hello world" kernel for riscv64 in Rust

Often times there's a large ramp up for starting out in embedded dev. I think Nix can substantially lower the barrier to entry. Furthermore, writing in Rust prevents many a triple fault at compile time through the merits of its type system. Pairing the two seems like a good idea.

One of my biggest initial frustrations with embedded dev was getting a cross compiling toolchain. The "goto" cross compiler [page](https://wiki.osdev.org/GCC_Cross-Compiler) is pretty intimidating for a beginner. Even now, each time I've started on an embedded project it takes me anywhere from a few hours to a week to get the new toolchain built. With `nix` this goes from an undefined amount of time to minutes.

The repo I'm using for this example is located [here](https://github.com/DieracDelta/NixKernelTutorial). Note that I am not doing anything new: several rust kernels already exist and nix has great riscv support. I'm just rehashing and hopefully explaining.

Special thanks to:

- [Tock](https://github.com/tock/tock) for lots of great examples of inline assembly. They even have nix support!
- [This](https://github.com/noteed/riscv-hello-asm) github repo for a bare metal example.

# Expected Background

I'm writing this for readers new to the Nix ecosystem but who have some familiarity with the Nix language and flakes as well as with kernel development (though perhaps not with Rust).

# Setting up the dev environment

Before beginning development, we must install a bunch of requisite tooling. We use `nix` package manager for this purpose. More specifically, we'll use the experimental `flakes` feature, which provides convenient package pinning and an easy to use CLI.

First, we start with the generic `flake` template:

```nix
{
  description = "Example for presentation";
  inputs = {
    nixpkgs.url = "nixpkgs/master";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{self, nixpkgs, rust-overlay, naersk, ... }:
  {}
}
  ```

The outputs will build our kernel, and the inputs are fixed/"pinned" packages used to build our outputs. The inputs I've chosen are:

- Master branch of `nixpkgs`: The choice of master was pretty arbitrary, we could have done stable instead. Nixpkgs consists of a set of 80k+ package definitions in a monorepo to choose from. We'll use this to snag a bunch of packages like gcc, gdb, and qemu.
- `rust-overlay`: we'll use this for obtaining a version of the rust cross compiler and cargo.
- `naersk`: we'll use this for building our rust packages.

`output` is a function of the described pinned inputs. In theory, it will (sans compiler nondeterminism) always build the same outputs for the same set of inputs.

## GNU riscv cross compiler toolchain

First, we'll grab the gnu toolchain. In order to do so, we need to specify that this toolchain is cross compiled. The nixpkgs repo defines a function in its `default.nix` file. I'm informally abusing notation to use `{}` to denote an attribute set containing some type of metadata.

```
{system information} -> {package definitions}
```

We run `import` which tells nix to execute the `nixpkgs` function in its `default.nix` and return the result. In this case, we must provide some system information in an argument to this function: specifically that our host system (denoted `localSystem`) is `x8664` linux and our target system (denoted `crossSystem`) is riscv linux. We include the triples and ABI information:

```nix
riscvPkgs = import nixpkgs {
  localSystem = "${system}";
  crossSystem = {
    config = "riscv64-unknown-linux-gnu";
    abi = "lp64";
  };
};
```

This will return a package set targeting `riscv64-unknown-linux-gnu` with the `lp64` ABI assigned to the `riscvPkgs` variable. `riscvPkgs.gcc` will give us a gcc version compiled to run on a riscv linux host and compile to a riscv linux target. This is not quite what we want. Instead, we'll use `riscvPkgs.buildPackages.gcc` which returns a cross compiler from our host, x8664 linux, to our target, riscv64 linux. The reason this is denoted `buildPackages` is because these packages are used to build the target packages. These packages run on x8664 linux.

## Qemu

Nixpkgs contains a qemu package definition. So first, we'll need to get a version of nixpkgs targeting x86-64-linux. So we just import nixpkgs `default.nix` again, this time without specifying a crossSystem. Nixpkgs assumes the target is the same as the host by default:

```nix
pkgs = import nixpkgs {
  localSystem = "${system}";
};
```

Unfortunately, the qemu version in nixpkgs is slightly out of date. So, we'll need to override the source to get the latest version. We do this by providing an "overlay" which is a way to modify package definitions. When we import nixpkgs, we can provide a list of overlays/package definition overrides that nixpkgs will apply.

More technically, an overlay is a function that takes in the original nixpkgs package set and the final "result" package set. This overlay function overwrites package attributes in the original package set in its returned attribute set. That returned attribute set is then magically merged with all other overlays to form the final package set.

For example:

```nix
(final: prev:
  { qemu = null;}
)
```

This overwrites the qemu package with null. So our resulting package set with this overlay will simply be null. Now all that remains is to override the `src` attribute of the `qemu` package. We know that this is the right attribute to override since `nix edit nixpkgs#qemu` shows this attribute as the source location. We use the `overrideAttrs` package attribute: that attribute takes in a function with signature: `{oldAttributes} -> {newAttributes}`. The new attributes are then unioned with the old attributes and any duplicates are replaced with the values in `newAttributes`.

So, our final expression ends up as:
```nix
pkgs = import nixpkgs {
  localSystem = "x86_64-linux";
  overlays = [
    (final: prev:
      {
        qemu = prev.qemu.overrideAttrs (oldAttrs: {
          src = builtins.fetchurl {
            url = "https://download.qemu.org/qemu-6.0.0.tar.xz";
            sha256 = "1f9hz8rf12jm8baa7kda34yl4hyl0xh0c4ap03krfjx23i3img47";
          };
        });
      }
    )
  ];
};
```

`builtins.fetchurl` wgets the url prior to build time and ensures the sha256 hash matches. Now, from this we can just reach in and grab our modified qemu package via `pkgs.qemu`.

## Rust toolchain

Next, let's grab the rust cross compiler toolchain. To do this, we use the `rust-overlay` input flake. This flake provides a bunch of outputs. One for each toolchain we might want. We add this overlay to our overlay list in our `pkgs` definition to access the rust binaries `rust-overlay` provides:

```nix
...
  overlays = [rustoverlay.overlay ... ];
...
```


We're going to use a fairly recent version of nightly, so we grab the May 10th nightly release: `pkgs.rust-bin.nightly."2021-05-10.default"`. This is almost good enough, except it's not a cross compiler. The package definition is a *function* that takes input arguments. We can override those input arguments to say we would like a cross compiler by setting the override attribute:

```nix

rust_build = pkgs.rust-bin.nightly."2021-05-10".default.override {
  targets = [ "riscv64imac-unknown-none-elf" ];
  extensions = [ "rust-src" "clippy" "cargo" "rustfmt-preview" ];
};

```

Note I also overwrote the extensions attribute to provide standard rust tooling. Since nixpkgs doesn't have rustup, this is the declarative equivalent to 

```bash
rustup toolchain add riscv64imac-unknown-none-elf
rustup component add rust-src clippy cargo rustfmt-preview
```
To access this tooling, we just include the resulting `rust_build` derivation wherever we need it.

## Generating a Nix Shell

Using our imports, we can now add a development shell with all of these dependencies installed by defining a `devshell.x86_64-linux` attribute in our output attribute set:

```nix
devShell.x86_64-linux = pkgs.mkShell {
  nativeBuildInputs = [ pkgs.qemu rust_build riscvPkgs.buildPackages.gcc riscvPkgs.buildPackages.gdb ];
};
```

When we run `nix develop`, the packages listed in `nativeBuildInputs` will be built (or pulled from a local/remote cache) and included on our path. This is very useful for `per-project` tooling. Now that we have the relevant toolchains, we can write the rust kernel.

# Writing a "Hello World" Rust Kernel

Our rust kernel is a proof of concept that a 64 bit kernel targeting riscv may be written with rust. We'll target the `sifive_u` machine on qemu and use the openSBI bootloader as our bios.

## Boilerplate

We first create a `Cargo.toml` file. Pretty standard so far. We don't bother to specify any targets as the defaults are good enough. Then we create a `src/main.rs` file. We include a `_start` symbol and a panic handler. This is the bare minimum Rust requires to compile properly. We enable `no_std`, as we will only be using the `core` rust library on bare metal, `no_main` as initially we will not have a `main` function, and `naked_functions` as we do not want Rust to start pushing registers to the stack in `_start` before we have initialized the stack pointer.

```rust
#![no_std]
#![no_main]
#![feature(naked_functions)]

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
  loop {}
}

#[naked]
#[no_mangle]
pub extern "C" fn _start() -> ! {
  loop {}
}
```

The exclamation mark return type means that the functions do not return. Another compile time check by Rustc.


## Compiler invocation

We need to compile our kernel. It turns out that

```bash
cargo rustc --release --target="riscv64imac-unknown-none-elf"
```

will cross compile the kernel to a riscv64imac target. We invoke cargo in this unorthodox way because we'll need to pass flags to the linker later on. This command will also generate a `Cargo.lock` file that we must `git add` so nix flakes may track it.

In order to build our derivation with nix, we'll use `Naersk`. `Naersk` provides a `lib.x86_64-linux.buildPackage` function that will use cargo (and `Cargo.lock`) to build rust packages with nix. We tell `Naersk` to use our cross compiler by overriding its input rust toolchain (in the same way as the rust-overlay override):

```nix
naersk_lib = naersk.lib."${system}".override {
  rustc = rust_build;
  cargo = rust_build;
};
```

We use this `naersk_lib` to build our package:

```rust
sample_package = naersk_lib.buildPackage {
  pname = "example_kernel";
  root = ./.;
  cargoBuild = _orig: "CARGO_BUILD_TARGET_DIR=$out cargo rustc --release --target=\"riscv64imac-unknown-none-elf\"";
};
```

The `pname` is the "package name". `root` is the root is the directory in which `naersk` will invoke the `cargoBuild` command. `cargoBuild` is a function that takes in the default cargo build command (which we subsequently drop), and returns a new cargo build command to be used. The only difference here is that `CARGO_BUILD_TARGET` cannot be our source directory. We need Cargo to build in the derivation's output directory, so we set it to `$out` (which points there).

We'd also like a script that runs this in qemu. We can create one:

```nix
sample_usage = pkgs.writeScript "run_toy_kernel" ''
  #!/usr/bin/env bash
  ${pkgs.qemu}/bin/qemu-system-riscv64 -kernel ${sample_package}/riscv64imac-unknown-none-elf/release/nix_example_kernel -machine sifive_u
'';
```

This creates a sample script that runs the kernel nix builds (with openSBI as the bios) on the sifive_u machine. We will use this for testing.

In order to make these outputs accessible, we add them to the output attribute set:

```nix
packages.riscv64-linux.kernel = sample_package;
packages.riscv64-linux.defaultPackage = sample_package;
apps.x86_64-linux.toy_kernel = {
  type = "app";
  program = "${sample_usage}";
};
defaultApp.x86_64-linux = self.apps.x86_64-linux.toy_kernel;
```

`nix run .` executes the `defaultApp`. We can call this from *any* linux x8664 box by calling `nix run github:DieracDelta/NixKernelTutorial`. The same goes for `defaultPackage`. We may build the kernel by running `nix build .` or `nix build github:DieracDelta/NixKernelTutorial`.

## Adding a linker script

We want our kernel to do something: print hello world. In order to do this, we'll have to make sure our ELF sections get placed in the correct spot to match the memory map of the sifive_u machine. We'll also need a stack. When we `nix run` our kernel and look at serial output of qemu with what we have so far, we'll see openSBI printed: `Domain0 Next Address     : 0x0000000080200000 `. This tells us that OpenSBI expects our start symbol to be `0x80200000` for the sifive_u machine target.

Here's the example linker script I'm using:

```
OUTPUT_ARCH( "riscv" )

ENTRY( _start )

MEMORY
{
  ram (rwx) : ORIGIN = 0x80200000, LENGTH = 0x80000
}

SECTIONS
{
  .kernel : {
    *(.text .text.*)
    *(.rodata .rodata.*)
    *(.data .data.*)
  } > ram

  .stack (NOLOAD) : {
    . = . + 0x10000;
    PROVIDE(_end_stack = .);
  } > ram

}
```

I've chosen the RAM length attribute arbitrarily, but this allocates a `kernel` section to load in the elf sections into and a stack. We can see this in the objdump (`objdump -h riscv64imac-unknown-none-elf/release/nix_example_kernel`):

```
Sections:
Idx Name              Size      VMA               LMA               File off  Algn  Flags
  0 .text             000000d8  0000000080200000  0000000080200000  00001000  2**1  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .rodata           0000002b  00000000802000d8  00000000802000d8  000010d8  2**0  CONTENTS, ALLOC, LOAD, READONLY, DATA
  2 .data             00000efd  0000000080200103  0000000080200103  00001103  2**0  CONTENTS, ALLOC, LOAD, READONLY, DATA
  3 .stack            00010000  0000000080201000  0000000080201000  00002000  2**0  ALLOC
  4 .riscv.attributes 0000002b  0000000000000000  0000000000000000  00002000  2**0  CONTENTS, READONLY
  5 .comment          00000013  0000000000000000  0000000000000000  0000202b  2**0  CONTENTS, READONLY
```

To build this with cargo, we need to add an argument through llvm to the linker:

```nix
cargo rustc --release --target=\"riscv64imac-unknown-none-elf\" -- -Clink-arg=-Tlinker.ld
```

## Setting up the stack

In our `_start` function we must set up the stack. We can do this with some inline assembly:

```rust
extern "C" {
    static _end_stack: usize;
}
...
... fn _start( ... {
  asm!(
      "
          la sp, {end_stack}
          j main
      ",
      end_stack = sym _end_stack,
      options(noreturn)
  );
}
```

The `_end_stack` extern C definition tells the rust compiler to look for this symbol in the linker script. Then all we do is move the symbol into `sp`, and jump to main. We have to specify that the function does not return in order for the rust compiler's checks to pass. We'll also need to define a `main` function to actually jump to, which we'll do later on.

## Using OpenSBI to print

We're using OpenSBI as a SEE or Supervisor Execution Environment. It runs in M mode (equivalent to Ring 0 on x86) and ensures that the kernel (running in S-mode/Ring 1) doesn't have as much power. The kernel can make "syscalls" to the SEE in much the same way that a userspace application makes syscalls to the kernel.

We would like to print "hello world" to one of the UARTs. We could do this by implementing a UART driver, but it's easier to just let openSBI do it for us. Not to mention this post is getting rather long. According to the [SBI spec](https://github.com/riscv/riscv-sbi-doc/blob/master/riscv-sbi.adoc), if we do a syscall (ecall instruction) from S mode (which our kernel is running in) to SBI running in M mode with the SBI Extension ID (EID) of 1 stored in `a7`, and the address of the character we wish to print stored in `a0`, openSBI will print will print that character for us using its UART implementation. So we write a function to do this:

```rust
unsafe fn write_char(ch: u8) {
    asm!(
    "
    li a7, 0x1
    lw a0, 0({0})
    ecall
    " , in(reg) (&ch), out("a0") _, out("a7") _
    );
}
```
This is more or less the same as C's inline assembly, though more readable (to me at least). Note that `a0` and `a7` are clobbered, and the address of `ch` is used as an input. `&ch` is now accessible via `{0}`. We can then call this function in `main` to print hello world:

```rust
#[no_mangle]
pub extern "C" fn main() -> ! {
    unsafe {
        "Hello World from a nixified rust kernel :D\n"
            .chars()
            .for_each(|c| write_char(c as u8));
    }
    loop {}
}
```

And now we have a Rust kernel that prints "hello world" built by and runnable with nix. `nix run github:DieracDelta/NixKernelTutorial`

## Adding CI

It's trivial to add a github action that builds the kernel using `nix`. I've talked about this in my other posts so I won't repeat myself. See the `cachix.yml` workflow file.
