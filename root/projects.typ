#import "lib.typ": *
#show: schema.with("index")

#page-title[Projects by Justin Restivo]
#description[Open-source projects by Justin Restivo, including bpftop, nix-btm, srcbot, Nixpkgs contributions, HotShot consensus work at Espresso Systems and Nix tooling.]

Stuff I've built or contributed to, roughly newest first. Most of it involves Nix, Rust, or both. Everything else lives on #link("https://github.com/DieracDelta")[my GitHub].

= Recent

#project-grid[
  #project("bpftop", url: "https://github.com/DieracDelta/bpftop", tags: ("Rust", "eBPF", "TUI"))[
    An `htop`-style process monitor that walks the kernel task list with a BPF iterator instead of reading `/proc` for every process. A refresh is about 100 syscalls whether there are 1.5k or 11k processes; htop makes 70k to 350k. It also tracks per-process network and disk I/O, the owning systemd unit or container, NVIDIA GPU usage, and can freeze a whole cgroup so you can stop a runaway process without killing it.
  ]

  #project("nix-btm", url: "https://github.com/DieracDelta/nix-btm", tags: ("Rust", "C++", "Nix"))[
    `htop` for Nix. This started as a small ratatui toy and grew into a C++ logger plugin loaded into Nix, a daemon that matches build events to cgroups, and a TUI for watching, freezing, killing, renicing and memory-limiting builds across users and remote builders.
  ]

  #project("srcbot", url: "https://github.com/DieracDelta/srcbot", tags: ("Rust", "Nix", "Nixpkgs"))[
    A companion to `nixpkgs-review`. It builds the intermediate attributes a PR touches (`goModules`, `cargoDeps`, ...), fixes stale fixed-output hashes and pushes them to a branch, sweeps whole package sets to check they still build from source, and sends builds to remote machines for multi-arch checks.
  ]

  #project("shapeBPF", url: "https://github.com/DieracDelta/shapeBPF", tags: ("Rust", "eBPF", "Networking"))[
    Bandwidth shaping per process or cgroup, driven from a TUI. qdiscs cap upload, and a BPF program drops packets to cap download. Bandwidth-hungry processes can be moved into an ephemeral cgroup and throttled harder.
  ]

  #project("WRhythm", url: "https://github.com/DieracDelta/WRhythm", tags: ("Swift", "iOS", "watchOS"))[
    A Subsonic/Navidrome client for iPhone, macOS and Apple Watch. It can hand playback between devices, streams on the watch without a phone, caches recent and upcoming tracks for offline playback, and builds playlists with sonicSimilarity and #link("https://github.com/DieracDelta/audiomuse-ai-nix")[AudioMuse-AI] (which I also packaged with Nix).
  ]

  #project("tmux-revive-llms", url: "https://github.com/DieracDelta/tmux-revive-llms", tags: ("Rust", "tmux"))[
    A Rust replacement for `tmux-resurrect` and `tmux-continuum` that also resumes Claude Code and Codex sessions by ID when it restores panes. Tested with NixOS VM checks.
  ]

  #project("visp", url: "https://github.com/DieracDelta/visp-lang", tags: ("Rust", "Lisp", "Agents"), badge: "WIP")[
    A small Lisp for scripting coding-agent workflows: declare tracks of Claude or Codex steps, memory and pipelines, then run them against an issue in a worktree.
  ]

  #project("rsoq.nvim", url: "https://github.com/DieracDelta/rsoq.nvim", tags: ("Rust", "Neovim", "Coq"), badge: "WIP")[
    A Rust rewrite of #link("https://github.com/tomtomjhj/coq-lsp.nvim")[coq-lsp.nvim], loaded into Neovim as a native Lua module.
  ]
]

= Upstream

#project-grid[
  #project("Nixpkgs", url: "https://github.com/NixOS/nixpkgs/pulls?q=is%3Apr+author%3ADieracDelta+is%3Amerged", tags: ("Nix",))[
    130+ merged PRs. I maintain a handful of packages, mostly Rust ones.
  ]

  #project("psi-code", url: "https://github.com/siraben/psi-code", tags: ("C", "Lua", "TUI"))[
    A portable coding agent. I moved the TUI runtime into Lua and added Vim keybindings, OSC 52 yanking, theming, an OpenAI Codex OAuth provider, and message queueing with async tools.
  ]

  #project("agent-deck", url: "https://github.com/asheshgoplani/agent-deck", tags: ("Go", "tmux"))[
    Cut TUI lag by parsing much less tmux output.
  ]

  #project("Odds and ends", tags: ("Rust", "Nix"))[
    - #link("https://github.com/NixOS/nix")[Nix]: static library builds on aarch64-darwin
    - #link("https://github.com/tracel-ai/burn")[burn]: a `Tanh` module and a burn-jit compile fix
    - #link("https://github.com/immunant/c2rust")[c2rust]: Nix build fixes
    - #link("https://github.com/EdJoPaTo/tui-rs-tree-widget")[tui-rs-tree-widget]: ratatui upgrades
    - #link("https://github.com/johnrichardrinehart/oracle-cloud-nixos")[oracle-cloud-nixos]: iSCSI fixes
  ]
]

= Espresso Systems

At #link("https://www.espressosys.com/")[Espresso Systems] (2022–2024) I worked on consensus and networking. The repositories I worked on are open source:

#project-grid[
  #project("HotShot", url: "https://github.com/EspressoSystems/HotShot", tags: ("Rust", "Consensus", "libp2p"))[
    Consensus and data availability for Espresso's decentralized sequencer. I wrote the libp2p networking backend, consensus implementations including pipelined HotStuff, a consensus testing harness with some nifty procedural macros and type-foo, the Nix infra, and an #link("https://github.com/EspressoSystems/HotShot/tree/main/task")[async task harness] with some fun `Future` and `Stream` implementations. `pin_project` and I are now very good friends.
  ]

  #project("netlink fork", url: "https://github.com/EspressoSystems/netlink", tags: ("Rust", "Linux", "Networking"))[
    Exposes infra for adding custom qdiscs. I used it to automate network chaos on an AWS cluster and on my desktop: enter a fresh network namespace, link it to the main one, then stack qdiscs to add latency, drop packets and limit bandwidth. All of it was syscalls wrapped in Rust, without shelling out to `ip`.
  ]

  #project("Async crates", tags: ("Rust",))[
    #link("https://github.com/EspressoSystems/async-compatibility-layer")[async-compatibility-layer], so the same code runs on tokio or async-std, and #link("https://github.com/EspressoSystems/nll")[nll].
  ]
]

= Research and school

#project-grid[
  #project("detypstify", url: "https://github.com/detypstify/typic", tags: ("Rust", "ML", "Typst"))[
    OCR that turns images of math into Typst, running entirely in the browser. I worked on the UI, Typst to SVG rendering, in-browser inference, and the data and CI plumbing.
  ]

  #project("MIT Master's thesis", url: "https://dspace.mit.edu/handle/1721.1/129858", tags: ("Security", "RISC-V"))[
    Security on tagged architectures.
  ]

  #project("Flashcards", url: "https://github.com/DieracDelta/Flashcards", tags: ("Typst", "Anki"))[
    Anki decks from material I've self-studied and classes I've taken, written in Typst and generated with typ2anki.
  ]

  #project("BeaverDocs", url: "https://github.com/DieracDelta/BeaverDocs", tags: ("JavaScript", "CRDTs"))[
    An undergrad group project: a proof-of-concept peer-to-peer collaborative text editor. I worked on the RGATreeSplit CRDT used to represent text operations.
  ]

  #project("DuckeeGO", url: "https://github.com/DieracDelta/DuckeeGO", tags: ("Go", "Program analysis"))[
    An undergrad group project: a proof-of-concept concolic execution engine for Go. I worked on the augmentations to the Go AST.
  ]
]

= Older tooling

#project-grid[
  #project("Neovim config", url: "https://github.com/DieracDelta/vimconfig", tags: ("Lua", "Nix", "Neovim"))[
    My personal vim "distro", assembled with Nix and nix2vim, with the usual IDE bells and whistles. Try it with `nix run github:DieracDelta/vimconfig`. I gave a #link("https://www.youtube.com/watch?v=iwsoF9ISfaw")[talk at VimConf] about it (#link("https://github.com/DieracDelta/vimconf_talk")[repo]).
  ]

  #project("DAWN", url: "https://github.com/DieracDelta/DAWN", tags: ("Rust", "Nix", "DAP"))[
    Debug Adapter with Nix: a WIP implementation of the debug adapter protocol for Nix.
  ]

  #project("flake_generator", url: "https://github.com/DieracDelta/flake_generator", tags: ("Rust", "Nix"))[
    A CLI that uses skim and rnix to parse Nix flakes into an AST and edit it, for generating best-practice boilerplate. Mostly an excuse to play with Rowan, rust-analyzer's syntax tree library.
  ]

  #project("asm-lsp", url: "https://github.com/DieracDelta/asm-lsp", tags: ("Rust", "LSP", "RISC-V"), badge: "WIP")[
    A language server for RISC-V assembly, built on a Tree-sitter grammar and tower-lsp.
  ]

  #project("NixKernelTutorial", url: "https://github.com/DieracDelta/NixKernelTutorial", tags: ("Rust", "Nix", "RISC-V"))[
    A RISC-V kernel hello world in Rust, built with Nix. Goes with #cite("./posts/2021-05-30-nix-rust-riscv-toy-kernel.typ")[this post].
  ]

  #project("Alienware lights", url: "https://github.com/DieracDelta/lights", tags: ("C", "Linux"))[
    A SysV-style daemon and user-facing library for controlling the lights on the Alienware 15 R3.
  ]

  #project("deepfry", url: "https://github.com/DieracDelta/deepfry", tags: ("Python",))[
    Deep-fries screenshots with ImageMagick and Tesseract OCR.
  ]

  #project("Advent of Code", tags: ("Haskell", "Rust", "OCaml"))[
    An excuse to learn a new language every year: #link("https://github.com/DieracDelta/advent-of-code-2018")[2018] (OCaml), #link("https://github.com/DieracDelta/advent-of-code-2019")[2019] (Rust), #link("https://github.com/DieracDelta/advent-of-code-2020")[2020] (Haskell), #link("https://github.com/DieracDelta/advent-of-code-2021")[2021] and #link("https://github.com/DieracDelta/advent-of-code-2022")[2022].
  ]

  #project("This blog", url: "https://github.com/DieracDelta/DieracDelta.github.io", tags: ("Typst",))[
    Version four. It started as a self-hosted Vue site, which I dropped after someone broke into services on the same box (probably through a CVE I didn't patch fast enough). Then Hugo on GitHub Pages, then Hakyll because I like Haskell. Now it's Typst via #link("https://github.com/Glomzzz/typsite")[typsite], since Typst has an HTML backend and is far more capable than Markdown.
  ]
]
