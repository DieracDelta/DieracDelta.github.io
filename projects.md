## Opensource Projects I've worked on/am working on

### [Espresso Systems](https://www.espressosys.com/)

At Espresso Systems, we've open sourced a bunch of the repositories I've contributed to, including:

- [HotShot](https://github.com/EspressoSystems/HotShot), a consensus and DA solution for our decentralized sequencer. My contributions include:
  - A Libp2p networking backend
  - A testing harness for consensus including some pretty nifty procedural macros and type-foo
  - Consensus implementations including pipelined HotStuff
  - Nix infra for HotShot
  - An [asyncronous task abstraction/harness](https://github.com/EspressoSystems/HotShot/tree/main/task) for controlling and communication between tasks. This includes some pretty slick `Future` and `Stream` implementations. `pin_project` and I are now very good friends : D
- [A Netlink fork](https://github.com/EspressoSystems/netlink) that exposes infra for adding custom qdiscs. I used this to mess with the network on an AWS cluster and locally on my 5950x desktop in a automated way. I would enter a separate network namespace, link it to the main network namespace, then add a heap of qdiscs to limit memory bandwidth, add in articial latency, drop packets, etc. This was all done directly with syscalls wrapepd by Rust code instead of using `ip link` and `ns`.
- [This](https://github.com/EspressoSystems/async-compatibility-layer) and [this](https://github.com/EspressoSystems/nll) crate

### NDA: [Nix DAP implementation](https://github.com/DieracDelta/nda)

WIP implementation of the debug adapter protocol for Nix.

### [RISCV Asm Lsp](https://github.com/DieracDelta/asm-lsp)

A (very WIP) language server for RISC-V assembly. Uses a TreeSitter parser and built with tower-lsp.

### [NixPkgs](https://github.com/NixOS/nixpkgs)

I maintain a couple of Rust packages.

### [VimConfig](https://github.com/DieracDelta/vimconfig)

My personal vim config, assembled with Nix and nix2vim. Comes with all the bells and whistles common in most IDEs. I gave a talk at [vimconf](https://www.youtube.com/watch?v=iwsoF9ISfaw) about it.

### [Flake Generator](https://github.com/DieracDelta/flake_generator)

A cli using skim + rnix to parse nix flakes into an AST and then modify that AST. Good for generating nix best practice boilerplate code.

### [Advent of Code](https://github.com/DieracDelta/advent-of-code-2020)

I try to run through these every year as an excuse to learn a new language. I've done most of [2020](https://github.com/DieracDelta/advent-of-code-2020), some of [2019](https://github.com/DieracDelta/advent-of-code-2019) and [2018](https://github.com/DieracDelta/advent-of-code-2018). This year ([2022](https://github.com/DieracDelta/advent-of-code-2022)) will probably be in Idris.

### [This blog](https://github.com/DieracDelta/DieracDelta.github.io)

A semi-autogenerated blog using nix + hakyll.

### [Kernel Tutorial](https://github.com/DieracDelta/NixKernelTutorial)

Tied to blog post, explains how to use nix to do kernel dev in Rust.

### [Flakes](https://github.com/DieracDelta/flakes)

An exercise in code obfuscation. My system configs for my various computers running NixOS.

### [Alienware](https://github.com/DieracDelta/lights)

SysV-style daemon and corresponding user-facing library for controlling the lights on the Alienware 15 R3 laptop.

### [Deepfrier](https://github.com/DieracDelta/deepfry)

Python script for deepfry-ing screenshots

### [MIT Master's thesis](https://dspace.mit.edu/handle/1721.1/129858)

Discusses security on a tagged architectures.

### [BeaverDocs](https://github.com/DieracDelta/BeaverDocs)

School project where I worked in group to create proof of concept peer to peer collaborative text editor. My contributions were to the RGATreeSplit CRDT implementation used internally to represent text operations.

### [DuckeeGO](https://github.com/DieracDelta/DuckeeGO)

School project where I worked in group to create proof of concept concolic execution engine for golang. My contributions were on augmentations to the golang AST.
