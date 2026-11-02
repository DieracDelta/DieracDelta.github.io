#import "lib.typ": *
#show: schema.with("index")

#page-title[Projects by Justin Restivo]
#description[Open-source projects by Justin Restivo, including bpftop, nix-btm, srcbot, Nixpkgs contributions, HotShot consensus work at Espresso Systems and Nix tooling.]

Stuff I've built or contributed to. Everything else lives on #link("https://github.com/DieracDelta")[my GitHub].

= Recent

#project-grid[
  #project("bpftop", url: "https://github.com/DieracDelta/bpftop", tags: ("Rust", "eBPF", "TUI"))[
    An `htop`-style process monitor that walks the kernel task list with a BPF iterator instead of reading `/proc` for every process. A refresh is about 100 syscalls whether there are 1.5k or 11k processes; htop makes 70k to 350k. It can also freeze a whole cgroup, so you can stop a runaway process without killing it.
  ]

  #project("Nix-Btm", url: "https://github.com/DieracDelta/nix-btm", tags: ("Rust", "C++", "Nix"))[
    #link("https://github.com/DieracDelta/nix-btm")[`btm` but for nix processes]. A simple tui I wrote to play around with the ratatui and sysinfo crates.

    It's since grown into a Nix plugin, a daemon and a TUI that can freeze, kill, renice and memory-limit builds.
  ]

  #project("srcbot", url: "https://github.com/DieracDelta/srcbot", tags: ("Rust", "Nix", "Nixpkgs"))[
    A companion to `nixpkgs-review`. It builds the intermediate attributes a PR touches (`goModules`, `cargoDeps`, ...), fixes stale fixed-output hashes and pushes them to a branch, and checks that whole package sets still build from source.
  ]

  #project("shapeBPF", url: "https://github.com/DieracDelta/shapeBPF", tags: ("Rust", "eBPF", "Networking"))[
    Per-process and per-cgroup bandwidth shaping from a TUI. qdiscs cap upload, and a BPF program drops packets to cap download. You can also move a bandwidth-hungry process into its own ephemeral cgroup and throttle it harder.
  ]

  #project("WRhythm", url: "https://github.com/DieracDelta/WRhythm", tags: ("Swift", "iOS", "watchOS"))[
    A Subsonic/Navidrome client for iPhone, macOS and Apple Watch. You can move playback between devices, stream on the watch without your phone, and keep listening offline from cached recent and upcoming tracks.
  ]

  #project("tmux-revive-llms", url: "https://github.com/DieracDelta/tmux-revive-llms", tags: ("Rust", "tmux"))[
    A Rust replacement for `tmux-resurrect` and `tmux-continuum` that also resumes Claude Code and Codex sessions by ID when it restores panes.
  ]

  #project("visp", url: "https://github.com/DieracDelta/visp-lang", tags: ("Rust", "Lisp", "Agents"), badge: "WIP")[
    A Lisp for scripting coding-agent workflows (Claude, Codex) and running them against an issue in a worktree.
  ]

  #project("rsoq.nvim", url: "https://github.com/DieracDelta/rsoq.nvim", tags: ("Rust", "Neovim", "Coq"), badge: "WIP")[
    A Rust rewrite of #link("https://github.com/tomtomjhj/coq-lsp.nvim")[coq-lsp.nvim].
  ]
]

= Upstream

#project-grid[
  #project("Nixpkgs", url: "https://github.com/NixOS/nixpkgs", tags: ("Nix",))[
    I maintain #link("https://github.com/NixOS/nixpkgs")[a couple of Rust packages in NixPkgs].
  ]

  #project("psi-code", url: "https://github.com/siraben/psi-code", tags: ("C", "Lua", "TUI"))[
    A portable coding agent. I moved its TUI into Lua and added Vim keybindings, OSC 52 yanking, an OpenAI Codex OAuth provider, and message queueing.
  ]

  #project("agent-deck", url: "https://github.com/asheshgoplani/agent-deck", tags: ("Go", "tmux"))[
    I cut its TUI lag by parsing less tmux output.
  ]

  #project("Odds and ends", tags: ("Rust", "Nix"))[
    - #link("https://github.com/NixOS/nix")[Nix]: static library builds on aarch64-darwin
    - #link("https://github.com/tracel-ai/burn")[burn]: a `Tanh` module and a burn-jit compile fix
    - #link("https://github.com/immunant/c2rust")[c2rust]: Nix build fixes
    - #link("https://github.com/EdJoPaTo/tui-rs-tree-widget")[tui-rs-tree-widget]: ratatui upgrades
    - #link("https://github.com/johnrichardrinehart/oracle-cloud-nixos")[oracle-cloud-nixos]: iSCSI fixes
  ]
]

= Espresso Sytems

At #link("https://www.espressosys.com/")[Espresso Systems], we've open sourced a bunch of the repositories I've contributed to, including:

- #link("https://github.com/EspressoSystems/HotShot")[HotShot], a consensus and DA solution for our decentralized sequencer. My contributions include:
  - A Libp2p networking backend
  - A testing harness for consensus including some pretty nifty procedural macros and type-foo
  - Consensus implementations including pipelined HotStuff
  - Nix infra for HotShot
  - An #link("https://github.com/EspressoSystems/HotShot/tree/main/task")[asyncronous task abstraction/harness] for controlling and communication between tasks. This includes some pretty slick `Future` and `Stream` implementations. `pin_project` and I are now very good friends : D
- #link("https://github.com/EspressoSystems/netlink")[A Netlink fork] that exposes infra for adding custom qdiscs. I used this to mess with the network on an AWS cluster and locally on my 5950x desktop in a automated way. I would enter a separate network namespace, link it to the main network namespace, then add a heap of qdiscs to limit memory bandwidth, add in articial latency, drop packets, etc. This was all done directly with syscalls wrapepd by Rust code instead of using `ip link` and `ns`.
- #link("https://github.com/EspressoSystems/async-compatibility-layer")[This] and #link("https://github.com/EspressoSystems/nll")[this] crate

= Research and school

#project-grid[
  #project("detypstify", url: "https://github.com/detypstify/typic", tags: ("Rust", "ML", "Typst"))[
    OCR that turns images of math into Typst, entirely in the browser. I worked on the UI, Typst-to-SVG rendering and in-browser inference.
  ]

  #project("MIT Master's Thesis", url: "https://dspace.mit.edu/handle/1721.1/129858", tags: ("Security",))[
    #link("https://dspace.mit.edu/handle/1721.1/129858")[My Master's thesis] discusses security on a tagged architectures.
  ]

  #project("Flashcards", url: "https://github.com/DieracDelta/Flashcards", tags: ("Typst", "Anki"))[
    A bunch of Anki #link("https://github.com/DieracDelta/Flashcards")[Flashcards] from self studied materials and prior classes I've taken. Generated using typ2anki.
  ]

  #project("BeaverDocs", url: "https://github.com/DieracDelta/BeaverDocs", tags: ("JavaScript", "CRDTs"))[
    #link("https://github.com/DieracDelta/BeaverDocs")[BeaverDocs] was a undergrad group project to create proof of concept peer to peer collaborative text editor. My contributions were to the RGATreeSplit CRDT implementation used internally to represent text operations.
  ]

  #project("DuckeeGO", url: "https://github.com/DieracDelta/DuckeeGO", tags: ("Go", "Program analysis"))[
    #link("https://github.com/DieracDelta/DuckeeGO")[DuckeeGO] was a undergrad group project where I worked in group to create proof of concept concolic execution engine for golang. My contributions were on augmentations to the golang AST.
  ]
]

= Older tooling

#project-grid[
  #project("Neovim", url: "https://github.com/DieracDelta/vimconfig", tags: ("Lua", "Nix", "Neovim"))[
    #link("https://github.com/DieracDelta/vimconfig")[My personal vim "distro"] , assembled with Nix and nix2vim. Comes with all the bells and whistles common in most IDEs. I gave a talk at #link("https://www.youtube.com/watch?v=iwsoF9ISfaw")[vimconf] about it.
  ]

  #project("DAWN", url: "https://github.com/DieracDelta/DAWN", tags: ("Rust", "Nix", "DAP"), badge: "WIP")[
    #link("https://github.com/DieracDelta/DAWN")[DAWN is a WIP Nix implementation] of the debug adapter protocol. Aka "Debug Adapter with Nix"
  ]

  #project("Flake Generator", url: "https://github.com/DieracDelta/flake_generator", tags: ("Rust", "Nix"))[
    #link("https://github.com/DieracDelta/flake_generator")[A cli using skim + rnix to parse nix flakes into an AST and then modify that AST]. Good for generating nix best practice boilerplate code.

    This was really an opportunity for me to play with Rust Analyzer's syntax tree library Rowan.
  ]

  #project("RISCV Asm Lsp", url: "https://github.com/DieracDelta/asm-lsp", tags: ("Rust", "LSP", "RISC-V"), badge: "WIP")[
    #link("https://github.com/DieracDelta/asm-lsp")[ A (very WIP) language server for RISC-V assembly]. Uses a TreeSitter parser and built with tower-lsp.
  ]

  #project("Kernel Tutorial", url: "https://github.com/DieracDelta/NixKernelTutorial", tags: ("Rust", "Nix", "RISC-V"))[
    #link("https://github.com/DieracDelta/NixKernelTutorial")[A Kernel Hello world tied to blog post], explains how to use nix to do kernel dev in Rust.
  ]

  #project("Alienware Lights", url: "https://github.com/DieracDelta/lights", tags: ("C", "Linux"))[
    #link("https://github.com/DieracDelta/lights")[A SysV-style daemon and corresponding user-facing library for controlling the lights on the Alienware 15 R3 laptop.]
  ]

  #project("Deepfrier", url: "https://github.com/DieracDelta/deepfry", tags: ("Python",))[
    #link("https://github.com/DieracDelta/deepfry")[Deepfrier] is a Python script for deepfry-ing screenshots using imagemagik and tesseractocr
  ]

  #project("AOC", tags: ("Haskell", "Rust", "OCaml"))[
    I try to run through Advent of Code every year as an excuse to learn a new language. I've done most of #link("https://github.com/DieracDelta/advent-of-code-2020")[2020], some of #link("https://github.com/DieracDelta/advent-of-code-2019")[2019] and #link("https://github.com/DieracDelta/advent-of-code-2018")[2018]. This year (#link("https://github.com/DieracDelta/advent-of-code-2022")[2022]) will probably be in Idris.
  ]

  #project("This Blog", url: "https://github.com/DieracDelta/DieracDelta.github.io", tags: ("Typst",))[
    #link("https://github.com/DieracDelta/DieracDelta.github.io")[My blog] has had several iterations:

    - I hosted a version written with vuejs, but got tired of maintaining the host after someone broke into some of the services I was hosting (presumably due to a cve I didn't patch quickly enough)
    - I moved to Hugo + github pages
    - I swapped out Hugo for Hakyll because I like Haskell.
    - Typst recently added a HTML backend, and I much prefer typst to markdown (it's just way more powerful). So, my blog's current iteration is in typst using Typsite.

    The core idea at each point was to maintain a markdown archive of thoughts.
  ]
]
