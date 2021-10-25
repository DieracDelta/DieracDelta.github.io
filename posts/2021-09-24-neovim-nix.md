---
author:
  name: "Justin Restivo"
date: 2021-09-24
title: "A Portable Text Editor: Nix <3 Neovim"
---

# Motivation

This post was borne out of my frustrations of repeatedly switching between servers with different versions of linux installed while not having root permissions and needing to develop. Setting up neovim with all the tools I'm used to was quite tedious. My workflow was as follows:

- Clone Neovim nightly (it consistently has really cool features!), install its deps, build it, and stick the result in `$HOME/usr/bin` and add `$HOME/usr/bin` to my `$PATH`.
- Intall system dependencies
- Install Vim Plug, wget a gist with my vimrc config in it, `:PlugInstall`.
- Install all the language servers I needed. This was the hard part, as that process differed for each language server. Some I grabbed off a github release, others I built manually from source as to get the most up-to-date version.

This might take me 30 minutes overall, and is both frustrating and tedious to set up and maintain on a large scale. My "solution" using `nix` is fast and easy to 

Please note that the work I'm describing here is not original. I'm (per usual) trying to make something that is reasonably complex understandable to a wider audience. Special thanks to:

- [Zach Coyle's Neovitality Nix distribution](https://github.com/vi-tality/neovitality) was my inspiration for this post. I present a *very* simple version of what's possible with Nix. Neovitality reaches for the stars and shows just how much is possible.
- [Shadow's](https://github.com/shadowninja55): neovim configuration was a great starting point to figure out "how" to configure with neovim.
- [Gytis](https://github.com/gytis-ivaskevicius) for providing feedback.

# Expected Background

This is meant to have a low barrier for entry. I intend the readers to be strangers to the Nix ecosystem (nix is not even be installed!) but are familiar with configuring Neovim with lua, neovim plugins, and linux.

# Getting Started: obtaining Nix

One can either do an install of nix or use DavHau's `nix-portable` project. I opt for the latter approach, since it's easier to set up and less commitment overall (no nix users need to be made). I wrote some wrapper scripts to ease the workflow that I'll explain here:

```bash
#!/usr/bin/env bash
NIX_PORTABLE_LOC="$PWD"
wget https://github.com/DavHau/nix-portable/releases/download/v008/nix-portable
chmod +x nix-portable
NP_LOCATION=$NIX_PORTABLE_LOC NP_RUNTIME='bwrap' $PWD/nix-portable nix
printf "\nsubstituters = https://cache.nixos.org https://jrestivo.cachix.org \ntrusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= jrestivo.cachix.org-1:+jSOsXAAOEjs+DLkybZGQEEIbPG7gsKW1hPwseu03OE=\n" >> $NIX_PORTABLE_LOC/.nix-portable/conf/nix.conf
printf "\nalias nix=\"NP_LOCATION=$NIX_PORTABLE_LOC NP_RUNTIME='bwrap' $PWD/nix-portable nix\"\n" >> $HOME/.bashrc
```

Nix portable is an awesome project that spins up an unprivileged container with `nix` and `flakes` installed. We snag the executable (bash script) on line 6, then run it on line 5. We tell `nix-portable` to use `$PWD/.nix-portable` as its container root directory by setting `NP_LOCATION`, and to use bubblewrap by setting `NP_RUNTIME` to bubblewrap.

Line 6 sets up the binary cache. The idea is to have Github CI (we'll get to this later) build neovim from source with our configuration and all our language servers/plugins and push it to a binary cache (using Cachix). We'll then pull down this "built" artifact from the binary cache on the server we wish to run on.

We'll be generating our vim configuration using `nix`. As a result, there's an `edit.sh` script that will listen for changes and regenerate our configuration. We'll set `autoload` in neovim to listen for the change to `flake.nix` and rebuilt our lua config. The script:

```bash
#!/usr/bin/env bash
# remember to set autoread in vim to autorefresh the file in vim
NIX_PORTABLE_LOC="$PWD"
find ./*.nix | entr -r bash -c "NP_LOCATION=$NIX_PORTABLE_LOC NP_RUNTIME='bwrap' $PWD/nix-portable nix build .#my_config -o init.nvim_store && cp -f $NIX_PORTABLE_LOC/.nix-portable/store/\$(basename \$(readlink $PWD/init.nvim_store)) $PWD/init.nvim"
```

`entr` is used to listen for a change to nix files. `entr` may need to be installed (`apt-get install -y entr` on Debian based distros). Upon change, we use `nix-portable` to build the config (`.#my_config`) and stick it in `$PWD/init.nvim_store`. However, this is a broken symlink to the nix store, and needs to be replaced. Some bash wizardry is used to recreate the path to the nix store from its location in `$PWD/.nix-portable/store`.

# Starting point

The repo I'll be explaining is located [here](https://github.com/DieracDelta/vimconf_talk/blob/0_initial_flake/flake.nix). Check out the `0_initial_flake`, as this will be our starting point.

The `flake` is written in Nix. Think a JSON like language with ML-ish syntax and lambda functions. Let's analyze the code. The top level looks like:

```nix
{
  inputs = { ... };
  outputs = inputs@{...}: {
  }
}
```

This can be thought of as a "pure" function from math. We input a set of pinned source code, and then `nix` builds some set of output build artifacts that are always the same for the same set of inputs. For the inputs, I've added neovim nightly (which has its own nix flake!), some vim plugins that I want to run on master, my home-brewn "nix to lua" translator/helper functions, and `rnix-lsp`--a language server for nix written in Rust.

Now, let's consider the outputs. The outputs are a function of the inputs: `inputs` refers to the entire attribute set, and the `{neovim, ...}` will destructure that attribute set one level. For example `neovim` binds to `inputs.neovim`.

Now I declare some variables:
```nix
my_config = "";
pkgs = import nixpkgs {system = "x86_64-linux";};
result_nvim = DSL.neovimBuilderWithDeps.legacyWrapper (neovim.defaultPackage.x86_64-linux) {
  extraRuntimeDeps = [];
  withNodeJs = true;
  configure.customRC = my_config;
  configure.packages.myVimPackage.start = with pkgs.vimPlugins; [ ];
};
```

Conceptually:

- `my_config` is where any plaintext config that would normally end up in a `init.lua` file would be placed.
- `pkgs` is a set of packages built for `x86_64-linux` (this is configurable!) built off of the master nixpkgs input. I won't explain the syntax here (see my Rust/Riscv blog post).
- `result_nvim` is the final product. I use my `DSL`'s legacyWrapper. Normally this would come from `nixpkgs`, but then it is difficult to pass in runtime dependencies. I've added the `extraRuntimeDeps` attribute to handle that in its own function exported from my DSL flake. `withNodeJs` builds the nodejs runtime into neovim, and `customRC` inserts `my_config` as our lua config file (albeit wrapped in a `init.nvim`). `configure.packages.myVimPackage.start` specifies a list of vim packages to make available when Neovim starts. `neovim.defaultPackage.x86_64-linux` builds our neovim off of the nightly `neovim` input.


The syntax might be intimidating at this point, but don't sweat too much. The idea isn't to question this template, as it should "just workTM". This initial layer of abstraction will allow us to create a powerful and portable vim build.

Then we use these variables to create outputs:

```nix
{
  my_config = pkgs.writeText "config" my_config;
  defaultPackage.x86_64-linux = result_nvim;
  defaultApp.x86_64-linux = {
      type = "app";
      program = "${result_nvim}/bin/nvim";
  };
};
```

We can inspect these outputs.
```
$ nix flake show
git+file:///home/jrestivo/Projects/vimtalk
├───defaultApp
│   └───x86_64-linux: app
├───defaultPackage
│   └───x86_64-linux: package 'neovim-master'
└───my_config: unknown
```

There are a few things we may do with this. First:

```nix
bash edit.sh
```

This will build our lua config on change to our flake. We can then open `init.nvim` and have a look at the generated lua inside. The `defaultPackage.x86_64-linux` attribute will build our "customized" neovim and store it in `result`:

`nix build .`

Finally, the `app` attribute will let us run `neovim` without having the repo cloned. We may either

```bash
nix run github:DieracDelta/vimconf_talk
# OR
nix run .
```

This CLI is very convenient to use from a user perspective. What I typically do on servers is (1) install nix-portable (run `./setup.sh`) and then (2) alias vim to `nix run github:DieracDelta/vimconf_talk`. Then I get all the vim goodness but setup is trivialized. This is the power of Nix.

Now, all that remains is to fill out the rest of the config.

# Configuring via DSL

Check out branch `1_dsl` to see the `DSL` in action. Keybinds are just lua calls. They have a natural representation in Nix as a JSON-like attribute set. For example:

```nix
{
  mode = "n";
  combo = "j";
  command = "gj";
  opts = {"noremap" = true; };
}
```

This translates to: `vim.api.nvim_set_keymap('n','j','gj',{ noremap = true})`.

Similarly `vim.o` and `vim.g` settings may be thought of the same way:

```nix
vim.g = {
  mapleader = " ";
  nofoldenable = true;
  noshowmode = true;
  completeopt = "menu,menuone,noselect";
};
vim.o = {
  termguicolors = true;
  ...
}
```

Sometimes we may also need to call lua functions. There's a somewhat natural representation as:

```nix
rawLua = [DSL.DSL.callFN "vim.cmd" ["syntax on"]]

```
which enables syntax. This, however, is a WIP since it still feels a bit clunky to me and nothing more than a proof of concept. Complex lua code should still remain as pasted in verbatim into `my_config` (we'll do this later).

We need to refactor slightly to fit this in. `DSL.DSL.neovimBuilder` takes in an attribute set of the form:

```nix
{
  extraConfig = "-- AT VERBATIM CONFIG GOES HERE";
  setOptions = {
    vim.g = {...};
    vim.o = {...};
  }
  keyBinds = [ ... ];
  rawLua = [ ... ];
  pluginInit = {}; # WIP not functional yet;
}
```

and produces a lua config file that we then feed into `legacyWrapper` in the argument attribute set.

# Adding plugins in nixpkgs

Check out branch `2_plugins`. Most plugins have been already packaged and live in `nixpkgs`. To see, we can run:

```nix
nix search nixpkgs $PLUGINNAME
```

Often times, the source is out of date. To tell, we can look at the revision:

```bash
nix edit nixpkgs#$PLUGINNAME
```

Now, I've gone through and done this for most of the plugins I use on a day-to-day basis. For the out of date ones, I add nix flake inputs and call `overrideAttrs`. `overrideAttrs` is a function that takes a function as an input of the form `(oldattrs: {...})`. This function takes in one argument, `oldattrs`, and returns an attribute set which is then merge with the old attribute set. It overwrites any attributes we specify. In this case, we just wish to override the source code (which we have done in multiple places):

```nix
configure.packages.myVimPackage.start = with pkgs.vimPlugins; [
  (telescope-nvim.overrideAttrs (oldattrs: { src = inputs.telescope-src; }))
  (cmp-buffer.overrideAttrs (oldattrs: { src = inputs.cmp-buffer; }))
  (nvim-cmp.overrideAttrs (oldattrs: { src = inputs.nvim-cmp; }))
  (cmp-nvim-lsp.overrideAttrs (oldattrs: { src = inputs.nvim-cmp-lsp; }))
  plenary-nvim
  nerdcommenter
  nvim-lspconfig
  lspkind-nvim
  (pkgs.vimPlugins.nvim-treesitter.withPlugins (
    plugins: with plugins; [tree-sitter-nix tree-sitter-python tree-sitter-c tree-sitter-rust]
  ))
  lsp_signature-nvim
  popup-nvim
];
```

Treesitter is an odd case. We do something similar except we add in many other plugins.


# Adding plugins outside nixpkgs

Check out `3_custom_plugin`. Sometimes plugins may not be added into `nixpkgs`. One example is the theme I like, `darcula`. Luckily, `nix` makes it easy to build plugins:

```nix
(pkgs.vimUtils.buildVimPluginFrom2Nix { pname = "dracula-nvim"; version = "master"; src = dracula-nvim; })
```

This uses a builtin `vim` plugin builder. We just need to name the plugin, specify its version and source (which is an input).

# Adding LSP

Check out `4_lsp`. We've already added all the plugins we need. Now all we need to do is (1) add the LSPs (and other system dependencies) we might need and (2) include configuration as plaintext. The former is done by filling out the `extraRuntimeDeps` attribute:

```nix
extraRuntimeDeps = with pkgs; [ripgrep clang rust-analyzer inputs.rnix-lsp.defaultPackage.x86_64-linux];
```

Note that we need ripgrep for telescope, clang for tree-sitter, and we are building `rnix-lsp` from source. All with very little effort!

I've just pasted what I would normally use to configure `neovim` into `my_config`. I won't explain this part as it is out of scope (and each individual plugin explains how this works in its respective readme).

# Adding CI

The last thing to do is enable a cache. The way to do this is to use a github action to build neovim and push it to github. It is trivial to copy `.github/workflows/nix.conf`. After copying, one must create their own [`cachix` account](https://www.cachix.org/), obtain a key to their cache, and set the `CACHIX_AUTH_TOKEN` github action secret to that key. Then, github actions will be able to push neovim binaries to this binary cache. Then client-side when we `nix run $NEOVIM_CONFIG`, `nix` will pull directly from this cache.



