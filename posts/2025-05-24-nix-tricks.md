---
author:
  name: "Justin Restivo"
date: 2025-05-24
title: "Nix tricks"
---

I'm dumping my quick dirty one liners here.

# Example of building an arbitrary nix expression

```bash
nix build -L --expr 'let nixpkgs_r = builtins.getFlake "github:NixOS/nixpkgs/1bede9101e0aa3c9f8f257cf02d4a9db092ffc6f"; in let pkgs = import nixpkgs_r { localSystem = { gcc.arch= "znver3"; gcc.tune = "znver3"; gcc.abi = "64"; system = "x86_64-linux"; }; crossSystem = { system = "x86_64-linux"; gcc.arch = "znver3"; gcc.tune = "znver3"; gcc.abi = "64"; }; }; in with pkgs; haskellPackages.crypton-x509-validation'
```

Note this includes flexibility on cross compiling as well as what is built.
