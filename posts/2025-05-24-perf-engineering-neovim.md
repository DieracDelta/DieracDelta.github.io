---
author:
  name: "Justin Restivo"
date: 2025-05-23
title: "Performance Engineering Neovim"
---

This is meant to be an objdump of measures I've taken to to bump the performance of neovim. But, I make no guarantees about *observable* speed improvements.

# Use bytecode

Neovim recently added a [feature](https://neovim.io/doc/user/lua.html#vim.loader.enable()) that compiles lua to bytecode and stores it in a cache by default located at `$HOME/.cache/nvim/luac/`. To enable and use this cache, add the following to your `init.lua`:

```lua
vim.loader.enable(true)
```

This significantly improves startup times for me since lua didn't have to re-interpret `.lua` files. Prior to enabling lazy loading, this improved my performance from `~300ms` startup to a `~200ms` startup.

To see the startup time, I used:

```
neovim --startuptime bmfile
```

where `bmfile` is a temporary file that neovim pipes output to.

Note: the first time the bytecode is compiled, there is a slowdown while neovim performs the compilation step.

Note: this isn't 100% for startup time optimization. Once adding lazy loading, plugins may be lazy loaded and thus make a difference on runtime performance.

# Lazy Loading

Conceptually, lazy loading of neovim plugins happens allows for some sort of event (for example, an autocmd) to load a neovim plugin. This allows for a faster startup and possibly a bit faster neovim when the plugins are not loaded.

There's a couple of options for lazy loaders. I ended up using [`lze`](https://github.com/BirdeeHub/lze).

# CPU optimizations

I've based this on this [reddit post](https://www.reddit.com/r/NixOS/comments/1b77j9i/comment/ktibbxq/), and roberth's suggestions [here](https://github.com/NixOS/nixpkgs/issues/49765).

We would like CPU specific instructions (e.g. AVX or SSE4 or something) to be enabled for each computer we build on. This *may* be faster than without these instructions in some cases.

To enable arch specific CPU optimizations, we specify the `hostSystem`, `localSystem`, and `targetSystem` when importing `nixpkgs`. In particular:

```
import pkgs {
      inherit overlays;
      # system that this will be built on
      hostSystem = {
        system = "x86_64-linux";
        gcc.arch = "znver3";
        gcc.tune = "znver3";
        gcc.abi = "64";
      };
      #
      localSystem = {
        system = "x86_64-linux";
        gcc.arch = "znver3";
        gcc.tune = "znver3";
        gcc.abi = "64";
      };
      # system to build to build for
      targetSystem = {
        system = "x86_64-linux";
        gcc.arch = "znver3";
        gcc.tune = "znver3";
        gcc.abi = "64";
      };
    };
```

Note that `localSystem` and `hostSystem` may vary depending on if the entire system is compiled with those features.

// TODO finish this once you figure out what this stuff means



# LTO

TODO I haven't gotten this to work yet
