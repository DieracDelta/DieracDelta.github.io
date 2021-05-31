---
author:
  name: "Justin Restivo"
date: 2021-02-15
title: Writing a "hello world" Riscv Kernel with Nix in Rust
---

# Motivation

The purpose of this tutorial is to showcase two main things:

- How great `nix` can be for speeding up embedded development
- Writing a "hello world" kernel for riscv64 in Rust

Often times there's a large ramp up for even getting hands wet with embedded dev, and I think Nix can substantially lower that barrier. Furthermore, writing in Rust prevents many a triple fault at compile time through the merits of its type system. Pairing the two seems like a good idea.

One of my biggest initial frustrations with embedded dev was getting a cross compiling toolchain. The "goto" cross compiler [page](https://wiki.osdev.org/GCC_Cross-Compiler) is pretty intimidating for a beginner. Even now, each time I've started on an embedded project it takes me anywhere from a few hours to a week to get the new toolchain built.

# Background

I'm writing this for readers new to the nix ecosystem but have familiarity with the language before as well as a familiarity with kernel development (though perhaps not with Rust).

# Setting up the dev environment

Before beginning development, a bunch of requisite tooling must be installed. This will be done through the `nix` package manager. More specifically, we'll use the experimental `flakes` feature, which provides convenient pinning and an easy to use CLI.

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
  ```

The outputs will build our kernel, and the inputs will be pinned packages used to build our inputs. The inputs I've chosen are:

- Master branch of `nixpkgs`: The choice of master was pretty arbitrary, we could have done stable instead. Nixpkgs consists of a set of 80k+ package definitions in a monorepo to choose from. We'll use this to snag a bunch of packages like gcc, gdb, and qemu.
- `rust-overlay`: we'll use this for obtaining a version of the rust cross compiler and cargo.
- `naersk`: we'll use this for building our rust packages.

`output` is a function of the described pinned inputs. In theory, it will (sans compiler nondeterminism) always build the same outputs for the same set of inputs.

## GNU riscv cross compiler toolchain

First, we'll grab the gnu toolchain. In order to do so, we need to specify that this toolchain is cross compiled. Nix makes this easy. The nixpkgs repo defines a function in its `default.nix` file:

```
[system information] -> [package definitions]
```

In order to invoke that function, we run `import` which tells nix to execute the function in the `default.nix` and return the result. In this case, we must some system information in an attribute set argument to this function: specifically that our host system (denoted localSystem) is x8664 linux and our target system (denoted crossSystem) is riscv linux. We include the triples and some information:

```nix
    riscvPkgs = import nixpkgs {
      localSystem = "${system}";
      crossSystem = {
        config = "riscv64-unknown-linux-gnu";
        abi = "lp64";
      };
    };
```

This will return us a package set targeting `riscv64-unknown-linux-gnu` with the `lp64` ABI under the `riscvPkgs` variable. `riscvPkgs.gcc` will give us a gcc version compiled to run on a riscv host that compiles to riscv. This is not quite what we want. Instead, we'll use `riscvPkgs.buildPackages.gcc`. This will get us a cross compiler from our host, x8664 linux, to our target, riscv64 linux. The reason this is denoted `buildPackages` is because these packages are used to build the target packages. That is, to build riscv packages targeting riscv.

## Qemu

Nixpkgs contains a qemu package definition. So first, we'll need to get a version of nixpkgs targeting x86-64-linux. So we just import nixpkgs `default.nix` again, this time without specifying a crossSystem. Nixpkgs assumes the target is the same as the host by default:

```nix
      pkgs = import nixpkgs {
        localSystem = "${system}";
      };
```

Unfortunately, the qemu version in nixpkgs is slightly out of date. So, we'll need to override the source to get the latest version. We do this by providing an "overlay" which is a way to modify package definitions. When we import nixpkgs, we can provide a list of overlays/package definition overrides that nixpkgs will apply.

More technically, an overlay is a function that takes in the original nixpkgs package set and the final "result" package set. This overlay function overwrites package attributes in the old package set in its returned attribute set. That returned attribute set is then magically merged with all other overlays to form the final package set.

For example:

```nix
(final: prev:
  { qemu = null;}
)
```

This overwrites the qemu package with null. So our resulting package set with this overlay will simply be null. Now all that remains is to override the `src` attribute of the `qemu` package. We know that this is the right attribute to override since `nix edit nixpkgs#qemu`shows this attribute as where the source is being placed. We use the `overrideAttrs` package attribute to do this. That attribute takes in a function: `{oldAttributes} -> {newAttributes}`. The new attributes are merged with the unioned attributes and any duplicates are replaced with the values in `newAttributes`.

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

`builtins.fetchurl` wgets url attribute at build time and ensures the sha256 hash matches. Now, from this we can just reach in and grab our modified qemu package via `pkgs.qemu`.

## Rust toolchain

Next, let's grab the rust cross compiler toolchain. To do this, we use the `rust-overlay` input. This input provides a bunch of outputs. One for each toolchain we might want. We add this overlay to our overlay list in our `pkgs` definition to gain access to rust binaries `rust-overlay` provides:

```nix
...
  overlays = [rustoverlay.overlay ... ];
...
```


We're going to use a fairly recent version of nightly, so we grab the May 10th one: `pkgs.rust-bin.nightly."2021-05-10.default"`. This is almost good enough, except it's not a cross compiler. The package definition is a *function* that takes input arguments. We can override those input arguments to say we would like a cross compiler by using the override attribute:

```nix

rust_build = pkgs.rust-bin.nightly."2021-05-10".default.override {
  targets = [ "riscv64imac-unknown-none-elf" ];
  extensions = [ "rust-src" "clippy" "cargo" "rustfmt-preview" ];
};

```

Note I also overwrote the extensions attribute as well; this will get us some convenient tooling. Since nixpkgs doesn't have rustup, this is the declarative equivalent to `rustup toolchain add riscv64imac-unknown-none-elf` and `rustup component add rust-src clippy cargo rustfmt-preview`. To access this tooling, we just include the `rust_build` derivation wherever we need it.

## Generating a Nix Shell

Using our imports, we can now add a development shell with all of these dependencies installed by defining a `devshell.x86_64-linux` attribute in our output attribute set:

```nix
devShell.x86_64-linux = pkgs.mkShell {
  nativeBuildInputs = [ pkgs.qemu rust_build riscvPkgs.buildPackages.gcc riscvPkgs.buildPackages.gdb ];
};
```

When we run `nix develop`, the packages listed in `nativeBuildInputs` will be built (or pulled from the cache) and inclued on our path. This is very useful for `per-project` tooling. Now, we can write the rust kernel.

# Writing a "Hello World" Rust Kernel

Our rust kernel is simply a proof of concept that a 64 bit kernel may be written and rust on qemu in rust. We'll target the `sifive_u` machine on qemu and use the openSBI bootloader our bios.

## Boilerplate

We first create a `Cargo.toml` file. Pretty standard so far. We don't bother to specify any targets. Then we create a `src/main.rs` file. We include a `_start` symbol and a panic handler. This is what Rust requires to compiler properly. We enable `no_std`, `no_main` and `naked_functions`, as we will only be using the `core` rust library and thus be running on bare metal.

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

The exclamation mark return type means that the functions do not return. The Rust compiler requires this.

Now we'll need to figure out how to compile this with cargo.

## Compiler invocation

```bash
cargo rustc --release --target=\"riscv64imac-unknown-none-elf\"
```

will build the kernel. It will also generate a `Cargo.lock` file that we can `git add`. In order to build our derivation with nix, we'll use `naersk`. `naersk` provides a `lib.x86_64-linux.buildPackage` function that will use cargo to build rust packages with nix. First, we tell `naersk` to use our cross compiler by overriding its input rust toolchain (in much the same fashion as earlier):

```nix
naersk_lib = naersk.lib."${system}".override {
  rustc = rust_build;
  cargo = rust_build;
};
```

Now, we can use this `naersk_lib` to build our package:

```rust
sample_package = naersk_lib.buildPackage {
  pname = "example_kernel";
  root = ./.;
  cargoBuild = _orig: "CARGO_BUILD_TARGET_DIR=$out cargo rustc --release --target=\"riscv64imac-unknown-none-elf\"";
};
```

The `pname` becomes the name of the package, and the root is the top level directory that `naersk` builds the package at. `cargoBuild` is a function that takes in the default cargo build command (which we subsequently drop), and return a new cargo build command to be used. The only difference here is that `CARGO_BUILD_TARGET` cannot be our source directory. We need it to be built in the derivation's output directory, so we set it to `$out` (which points there).

We'd also like a script that runs this for us in qemu. We can create one:

```nix
sample_usage = pkgs.writeScript "run_toy_kernel" ''
  #!/usr/bin/env bash
  ${pkgs.qemu}/bin/qemu-system-riscv64 -kernel ${sample_package}/riscv64imac-unknown-none-elf/release/nix_example_kernel -machine sifive_u
'';
```

This creates a sample script that runs the kernel nix builds (with openSBI as the bios) on the sifive_u machine. We will use this for testing.

In order to make these outputs accessible, we must add them to the output attribute set:

```nix
packages.riscv64-linux.kernel = sample_package;
packages.riscv64-linux.defaultPackage = sample_package;
apps.x86_64-linux.toy_kernel = {
  type = "app";
  program = "${sample_usage}";
};
defaultApp.x86_64-linux = self.apps.x86_64-linux.toy_kernel;
```

The `defaultApp` is the application that is run on the local repo when `nix run .` is executed; we make this our bash script. Furthermore, we can call this from any x8664 machine running linux by calling `nix run github:DieracDelta/NixKernelTutorial`. The same goes for `defaultPackage`. This may be build by running `nix build .` or `nix build github:DieracDelta/NixKernelTutorial`.

## Adding a linker script

We want our kernel to do something actually useful: to print hello world. In order to do this, we'll have to make sure our ELF sections get placed in the correct spot to match the memory map of the sifive_u board. We'll also need a stack. Our requirements are: OpenSBI expects the `_start` symbol at `0x80200000` on the `sifive_u` machine. We know this because when we `nix run` our kernel and look at serial output of qemu with what we have so far, we'll see openSBI printed: `Domain0 Next Address     : 0x0000000080200000 `.

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
    *(.text.init) *(.text .text.*)
    *(.rodata .rodata.*)
    *(.sdata .sdata.*) *(.data .data.*)
    *(.sbss .sbss.*) *(.bss .bss.*)
  } > ram

  .stack (NOLOAD) : {
    . = . + 0x10000;
    PROVIDE(_end_stack = .);
  } > ram

}
```

This should see familiar. I've chosen the length attribute arbitrarily, but this allocates a `kernel`section to load in the elf sections into. It places the `text.init` section fist, then the rest of the common sections you'll find in an elf.

I've also allocated a stack region of size `0x10000`.

To build this with cargo, we need to add an argument through llvm and to the linker:

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
... _ start ...
asm!(
    "
        la sp, {end_stack}
        j main
    ",
    end_stack = sym _end_stack,
    options(noreturn)
);
```

The `_end_stack` extern C definition tells the rust compiler to look for this symbol in the linker script. Then all we do is move the symbol into `sp`, and jump to main. We have to specify that the function does not return in order for the rust compiler to not return errors. We'll need to define a `main` function to actually jump to, which we'll do later on.

## Using OpenSBI to print

We're using OpenSBI as a SEE or Supervisor Execution Environment. It runs in M mode (equivalent to Ring 0 on x86) and ensures that the kernel (running in S-mode/Ring 1) doesn't have as much power. The kernel can make "syscalls" to the SEE in much the same way that a userspace application makes syscalls to the kernel.

We would like to print "hello world" to the uart. We could do this by implementing a UART driver, but it's easier to just let openSBI do it for us. According to the [SBI spec](https://github.com/riscv/riscv-sbi-doc/blob/master/riscv-sbi.adoc), if we do a syscall (ecall instruction) from S mode (which our kernel is running in) to SBI with the SBI Extension ID (EID) of 1 stored in`a7`, and the address of the character we wish to print stored in `a0`, openSBI will print will print that character for us using its UART implementation. So we write a function to do this:

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
This is more or less the same as C's inline assembly. Note that `a0` and `a7` are clobbered. Furthermore we wish to put the address of `ch` as an input. We do this by saying (in english) use input register for the address of `ch`. This is now accessible via `{0}`. We can then call this function in `main` to print hello world:

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

And now we have a Rust kernel that prints "hello world". Admitteldy it's not flashy, but it works.
```

## Adding CI

It's trivial to add a github action that builds the kernel using `nix`. I've talked about this in my other posts so I won't repeat myself. See the `cachix.yml` workflow file.
