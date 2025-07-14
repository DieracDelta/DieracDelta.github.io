#import "../lib.typ": *
#show: schema.with("page")

#title[s\/Rust\/Ocaml]
#date[2025-07-24]
#author[Justin Restivo]

= Motivation

As part of my research, I've been playing around with the certified compiler CompCert a bunch. As usual, I've been using Nix for development. CompCert is written primarily in ocaml (the "certified" part written in Coq is extracted to Ocaml). Of course, getting Ocaml and Coq building with `Nix` is really trivial.

But, I need to share my code outside my Nixy walled garden. To that end, I want to compile CompCert to WASM (this gives a nice github pages demo) and as a statically compiled binary ( for other linux devs who don't use NixOS for everything).

As it turns out, I've hit both of these things using `nix` and Rust. I can snag a Musl target for Rustc, set `RUSTFLAGS` appropriately, and produce a statically linked binary. Similarly, since Rust is built on LLVM, and LLVM has a WASM target, Rust compiles to WASM really easily (further, `wasm-pack` trivializes this).

So the question I had last week was: how hard is this to do this with Ocaml for CompCert?

= Problem \#1: Dune

CompCert uses direct calls to `ocamlc`/`ocamlopt`/`ocamldeps` instead of using one of the many ocaml build tools. This immediately creates complications:
