#import "lib.typ": *
#show: schema.with("index")

= Opensource Projects I've worked on/am working on

== Flashcards

A bunch of Anki #link("https://github.com/DieracDelta/Flashcards")[Flashcards] from self studied materials and prior classes I've taken. Generated using typ2anki.

== Nix-Btm

#link("https://github.com/DieracDelta/nix-btm")[`btm` but for nix processes]. A simple tui I wrote to play around with the ratatui and sysinfo crates.

== Espresso Sytems

At #link("https://www.espressosys.com/")[Espresso Systems], we've open sourced a bunch of the repositories I've contributed to, including:

- #link("https://github.com/EspressoSystems/HotShot")[HotShot], a consensus and DA solution for our decentralized sequencer. My contributions include:
  - A Libp2p networking backend
  - A testing harness for consensus including some pretty nifty procedural macros and type-foo
  - Consensus implementations including pipelined HotStuff
  - Nix infra for HotShot
  - An #link("https://github.com/EspressoSystems/HotShot/tree/main/task")[asyncronous task abstraction/harness] for controlling and communication between tasks. This includes some pretty slick `Future` and `Stream` implementations. `pin_project` and I are now very good friends : D
- #link("https://github.com/EspressoSystems/netlink")[A Netlink fork] that exposes infra for adding custom qdiscs. I used this to mess with the network on an AWS cluster and locally on my 5950x desktop in a automated way. I would enter a separate network namespace, link it to the main network namespace, then add a heap of qdiscs to limit memory bandwidth, add in articial latency, drop packets, etc. This was all done directly with syscalls wrapepd by Rust code instead of using `ip link` and `ns`.
- #link("https://github.com/EspressoSystems/async-compatibility-layer")[This] and #link("https://github.com/EspressoSystems/nll")[this] crate

== DAWN

#link("https://github.com/DieracDelta/DAWN")[DAWN is a WIP Nix implementation] of the debug adapter protocol. Aka "Debug Adapter with Nix"

== RISCV Asm Lsp

#link("https://github.com/DieracDelta/asm-lsp")[ A (very WIP) language server for RISC-V assembly]. Uses a TreeSitter parser and built with tower-lsp.

== Nixpkgs

I maintain #link("https://github.com/NixOS/nixpkgs")[a couple of Rust packages in NixPkgs].

== Neovim

#link("https://github.com/DieracDelta/vimconfig")[My personal vim "distro"] , assembled with Nix and nix2vim. Comes with all the bells and whistles common in most IDEs. I gave a talk at #link("https://www.youtube.com/watch?v=iwsoF9ISfaw")[vimconf] about it.

== Flake Generator

#link("https://github.com/DieracDelta/flake_generator")[A cli using skim + rnix to parse nix flakes into an AST and then modify that AST]. Good for generating nix best practice boilerplate code.

This was really an opportunity for me to play with Rust Analyzer's syntax tree library Rowan.

== AOC

I try to run through Advent of Code every year as an excuse to learn a new language. I've done most of #link("https://github.com/DieracDelta/advent-of-code-2020")[2020], some of #link("https://github.com/DieracDelta/advent-of-code-2019")[2019] and #link("https://github.com/DieracDelta/advent-of-code-2018")[2018]. This year (#link("https://github.com/DieracDelta/advent-of-code-2022")[2022]) will probably be in Idris.

== This Blog

#link("https://github.com/DieracDelta/DieracDelta.github.io")[My blog] has had several iterations:

- I hosted a version written with vuejs, but got tired of maintaining the host after someone broke into some of the services I was hosting (presumably due to a cve I didn't patch quickly enough)
- I moved to Hugo + github pages
- I swapped out Hugo for Hakyll because I like Haskell.
- Typst recently added a HTML backend, and I much prefer typst to markdown (it's just way more powerful). So, my blog's current iteration is in typst using Typsite.

The core idea at each point was to maintain a markdown archive of thoughts.

== Kernel Tutorial

#link("https://github.com/DieracDelta/NixKernelTutorial")[A Kernel Hello world tied to blog post], explains how to use nix to do kernel dev in Rust.

== Flakes

#link("https://github.com/DieracDelta/flakes")[My flake config. Aka an exercise in code obfuscation]. My system configs for my various computers running NixOS.

== Alienware Lights

#link("https://github.com/DieracDelta/lights")[A SysV-style daemon and corresponding user-facing library for controlling the lights on the Alienware 15 R3 laptop.]

== Deepfrier

#link("https://github.com/DieracDelta/deepfry")[Deepfrier] is a Python script for deepfry-ing screenshots using imagemagik and tesseractocr

== MIT Master's Thesis

#link("https://dspace.mit.edu/handle/1721.1/129858")[My Master's thesis] discusses security on a tagged architectures.

== BeaverDocs

#link("https://github.com/DieracDelta/BeaverDocs")[BeaverDocs] was a undergrad group project to create proof of concept peer to peer collaborative text editor. My contributions were to the RGATreeSplit CRDT implementation used internally to represent text operations.

== DuckeeGO

#link("https://github.com/DieracDelta/DuckeeGO")[DuckeeGO] was a undergrad group project where I worked in group to create proof of concept concolic execution engine for golang. My contributions were on augmentations to the golang AST.
