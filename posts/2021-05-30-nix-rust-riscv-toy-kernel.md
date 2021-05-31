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

# Writing Rust Kernel

## Compiler invocation

## Adding a linker script

## Allocating a stack

## Using OpenSBI to print

## Debugging with GDB

# Packaging

## Kernel

## Qemu

## Adding CI
