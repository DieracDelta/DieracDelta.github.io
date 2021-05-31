---
author:
  name: "Justin Restivo"
date: 2021-02-15
title: Writing a "hello world" Riscv Kernel with Nix in Rust
---

# Motivation

The purpose of this tutorial is to showcase two main things:

- How great `nix` can be for embedded development
- Writing a "hello world" kernel for riscv in rust

Often times there's a large ramp up for even getting hands wet with embedded dev, and I think Nix can defnitely be used to lower that barrier substantially. Furthermore, writing in Rust prevents many a triple fault at compile time by through the merits of its type system. Pairing the two seemed like a good idea.

# Setting up the dev environment

Before beginning development, a bunch of requisite tooling must be installed. This will be done through the `nix` package manager. More specifically, we'll use the experimental `flakes` feature, which provides convenient pinning and an easy to use CLI.

## Rust toolchain

## GNU riscv cross compiler toolchain

## Qemu

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
