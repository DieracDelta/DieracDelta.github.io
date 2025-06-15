#import "../lib.typ": *
#show: schema.with("page")

#title[Performance Engineering Neovim]
#date[2025-05-24]
#author[Justin Restivo]

This is meant to be an objdump of measures I've taken to to bump the performance of neovim. But, I make no guarantees about *observable* speed improvements.

= Use bytecode

Neovim recently added a #link("https://neovim.io/doc/user/lua.html#vim.loader.enable()")[feature] that compiles lua to bytecode and stores it in a cache by default located at `$HOME/.cache/nvim/luac/`. To enable and use this cache, add the following to your `init.lua`:

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

= Lazy Loading

Conceptually, lazy loading of neovim plugins happens allows for some sort of event (for example, an autocmd) to load a neovim plugin. This allows for a faster startup and possibly a bit faster neovim when the plugins are not loaded.

There's a couple of options for lazy loaders. I ended up using #link("https://github.com/BirdeeHub/lze")[`lze`].

The way this works is in three steps:

First, mark the plugins you want to load lazily as `optional`. In `mnw`, this is done by setting the `plugins.opt` attribute in the `mnw.lib.wrap` function (#link("https://github.com/DieracDelta/vimconfig/blob/21ede78b6e32e60e97553fe70fe384a2335f5814/flake.nix#L607")[example]).

Then, include a snippet that provides a trigger and initialization options. For example,

```lua
require("lze").load {
  "ferris-nvim", -- plugin name to load
  ft = {"rust"}, -- the event is opening a rust file
  after = function()
    -- configuration that is performed when the event is hit
    require('ferris').setup({})
    vim.api.nvim_set_keymap('n', '<leader>rl', '<cmd>lua require("ferris.methods.view_memory_layout")()<cr>', {})
    vim.api.nvim_set_keymap('n', '<leader>rhi', '<cmd>lua require("ferris.methods.view_hir")()<cr>', {})
    vim.api.nvim_set_keymap('n', '<leader>rmi', '<cmd>lua require("ferris.methods.view_mir")()<cr>', {})
    vim.api.nvim_set_keymap('n', '<leader>rb', '<cmd>lua require("ferris.methods.rebuild_macros")()<cr>', {})
    vim.api.nvim_set_keymap('n', '<leader>rm', '<cmd>lua vim.cmd.RustLsp("expandMacro")<cr>', {})
  end,
}
```

= CPU optimizations (Cross Compilation)

I've based this on this #link("https://www.reddit.com/r/NixOS/comments/1b77j9i/comment/ktibbxq/")[reddit post].

We would like CPU specific instructions (e.g. AVX or SSE4 or something) to be enabled for each computer we build on. This *may* be faster than without these instructions in some cases.

To enable arch specific CPU optimizations, we specify the `hostSystem`, `localSystem`, and `targetSystem` when importing `nixpkgs`. In particular:

```
import pkgs {
      inherit overlays;
      # the system being built *on*
      localSystem = {
        system = "x86_64-linux";
        gcc.arch = "znver3";
        gcc.tune = "znver3";
        gcc.abi = "64";
      };
      # the system to build *for*
      hostSystem = {
        system = "x86_64-linux";
        gcc.arch = "znver3";
        gcc.tune = "znver3";
        gcc.abi = "64";
      };
      # compilers (probably doesn't apply much) emit binaries with vector instructions
      targetSystem = {
        system = "x86_64-linux";
        gcc.arch = "znver3";
        gcc.tune = "znver3";
        gcc.abi = "64";
      };
    };
```

The `gcc.*` and `system` attributres will of course be processor specific, but in the case of my AMD 5950x threadripper, will enable the extra instruction sets that are supported by the zen3 microarchitecture.

But, that's it.

Useful links to follow about this cross compilation step:

- We're due for a change to `buildSystem` to match the NixOS derivation `buildPlatform` once #link("https://github.com/NixOS/nixpkgs/pull/324614/files")[this PR is merged]
- What do these parameters actually mean? Check the #link("https://nixos.org/manual/nixpkgs/stable/#possible-dependency-types")[nixos documentation here] and the #link("https://github.com/NixOS/nixpkgs/blob/master/doc/stdenv/cross-compilation.chapter.md")[nixpkgs documentation here]
  - buildPlatform is the machine doing the building
  - hostPlatform is the machine to run the built binary (possibly a compiler) on
  - targetplatform is the machine a compiler running on hostPlatform will emit binaries for

= LTO

TODO I haven't gotten this to work yet
