#import "../lib.typ": *
#show: schema.with("page")

#title[Running NixOS like Gentoo]
#date[2026-01-11]
#author[Justin Restivo]
#description[Getting Gentoo-style customization on NixOS, such as building packages for a specific CPU like znver3, while keeping Nix builds pure.]

I used to daily drive Gentoo before NixOS. Nix's value add was that it had the nice parts of Gentoo (the useflags, customizability, and from-source packages) while retaining the usability of something like Ubuntu. Since I've come to Nix, I've wanted to run it like Gentoo: all the useflags, mega optimization, custom linker, etc. Here's a writeup of how I've made rebuilding the world every week with all the #link("https://www.shlomifish.org/humour/by-others/funroll-loops/Gentoo-is-Rice.html")[bells and whistles] of Gentoo ferrari practical.

= -march=native (Arch specific optimizations)

Caveat: while you *can* do this with `-march=native`, I think that's against the idea of Nix. It's definitionally impure, and I love Nix's purity. Instead, I will choose the architecture of my 5950x processor's `znver3`.

To do this, I had to take three steps. First: enable the ability to build for znver3:

```nix
nix.settings.system-features = [
  # ..
  "gccarch-znver3"
];
```

This *enables* nix to build programs for znver3. Since I'm already on a znver3 machine, this enabled me to target the machine I'm running on.

Next, I enabled the relevant flags by setting `mtune` and `march` config options when importing nixpkgs:

```nix
import nixpkgs {
  # "my current system is x86_64-linux"
  localSystem = "x86_64-linux";
  # I want to build for znver3 microarch
  hostPlatform = {
    system = "x86_64-linux";
    gcc.arch = "znver3";
    gcc.tune = "znver3";
    gcc.abi = "64";
  };
  # I want any compilers I build to target znver3 microarch
  targetPlatform = {
    system = "x86_64-linux";
    gcc.arch = "znver3";
    gcc.tune = "znver3";
    gcc.abi = "64";
  };
}
```

There's a chicken and egg problem here that bit me the first time. The very first build happens on a system that *isn't* built for znver3, so `localSystem` is plain x86_64. Once you've switched to the znver3 config, the machine you're building on is itself znver3, and you need the flags on both sides. I wrote up a bit more about this on #link("https://discourse.nixos.org/t/nix-cpu-global-cpu-flags/21507/4")[discourse].

We can take a similar action on the GPU. Nvidia has a config option to say which cuda compute capability to use:

```nix
import nixpkgs {
  # ..
  config = {
    cudaSupport = true;
    cudaCapabilities = [ "8.9" ];
  };
}
```

This allows me to emit optimized cuda code for my specific card (4090), instead of building every kernel for every GPU generation.

Note: if you set `config.warnUndeclaredOptions = true;`, nixpkgs will warn about `cudaCapabilities` (and `replaceStdenv`, more on that later) because they aren't declared options. I #link("https://github.com/NixOS/nixpkgs/issues/479220")[opened an issue] about it.

= More `march=native`

Setting `gcc.arch` only gets you C and C++. Every other language has its own compiler with its own flag, so each one needs its own overlay.

== Rust

Rust wants `-C target-cpu=znver3`. My first attempt (back in 2025) was to patch nixpkgs itself to thread a `RUSTFLAGS` option through `makeRustPlatform`. That works, but carrying a patch on nixpkgs is annoying. The overlay I ended up with extends `buildRustPackage` and appends to `NIX_RUSTFLAGS`, which the nixpkgs rustc wrapper picks up:

```nix
_final: prev:
let
  inherit (prev) lib;
  isZen3Target = (prev.stdenv.hostPlatform.gcc.arch or null) == "znver3";
in
lib.optionalAttrs isZen3Target {
  rustPlatform = prev.rustPlatform.overrideScope (
    _rustFinal: rustPrev: {
      buildRustPackage = lib.extendMkDerivation {
        constructDrv = rustPrev.buildRustPackage;
        extendDrvArgs = _finalAttrs: previousAttrs: {
          env = (previousAttrs.env or { }) // {
            NIX_RUSTFLAGS = lib.concatStringsSep " " (
              builtins.filter (value: value != "") [
                (toString (previousAttrs.env.NIX_RUSTFLAGS or ""))
                "-C target-cpu=znver3"
              ]
            );
          };
        };
      };
    }
  );
}
```

The `isZen3Target` check means the overlay does nothing if I import nixpkgs without the znver3 platform (e.g. for another machine).

== Zig

Zig defaults to `-Dcpu=baseline`. The zig setup hook in nixpkgs passes a default cpu flag to every `zig build`, so the fix is to override that flag on every zig version:

```nix
customizeZig =
  drv:
  drv.overrideAttrs (old: {
    env = (old.env or { }) // {
      zig_default_cpu_flag = "-Dcpu=znver3";
    };
  });

zigTargets = builtins.filter (
  name: name == "zig" || builtins.match "zig_[0-9]+_[0-9]+" name != null
) (builtins.attrNames prev);
```

Note: this used to be a `globalBuildFlags` argument to the zig hook. That changed in #link("https://github.com/NixOS/nixpkgs/pull/473413")[nixpkgs\#473413], which is why the overlay looks the way it does now.

== Haskell

GHC was the most annoying. GHC's native code generator doesn't take `-march` directly, but it does let you pass flags through to the tools it calls. `-optc` goes to the C compiler, and `-optlo` goes to LLVM's `opt` if you use the LLVM backend (`-fllvm`):

```nix
mkDerivation =
  args:
  hprev.mkDerivation (
    args
    // {
      configureFlags = (args.configureFlags or [ ]) ++ [
        (makeGhcOptions [
          # "-fllvm"
          "-optc=-march=znver3"
          "-optlo=-mcpu=znver3"
          "-O2"
        ])
      ];
    }
  );
```

I originally had `-fllvm` on, and xmobar stopped building with a cycle between its outputs:

```
error: cycle detected in build of '/nix/store/...-xmobar-0.49.drv' in the references of output 'bin' from output 'out'
```

I #link("https://github.com/NixOS/nixpkgs/issues/414362")[opened an issue] for this. Someone on the NixOS discord pointed out that setting `enableSeparateBinOutput = false` makes it go away, and sternenseemann pointed out it's a variant of #link("https://github.com/NixOS/nixpkgs/issues/140774")[\#140774] (haskell packages with a separate bin output ending up in a reference cycle). Normally GHC's dead code elimination removes the reference, and nobody is quite sure why it doesn't here. I ended up applying the same workaround to `cachix` and `yaml` too. Along the way `wherefrom-compat`'s tests also broke, and TeofilC tracked it down to the LLVM backend not supporting the `wherefrom` primop (#link("https://gitlab.haskell.org/ghc/ghc/-/issues/26435")[ghc\#26435]). As you can see from the commented out `-fllvm`, I eventually gave up on the LLVM backend.

= Does this actually work?

Okay, so in theory at this point we applied use flags everywhere. But...how do we check that in practice we did actually do that? I used #link("https://github.com/pkgw/elfx86exts")[`elfx86exts`], which disassembles a binary and tells you which instruction set extensions it uses. As a case study I built htop from source with and without `-march=native`. Without:

```
File format and CPU architecture: Elf, X86_64
MODE64 (call)
CMOV (cmovge)
SSE2 (movd)
SSE1 (movups)
BMI (tzcnt)
Instruction set extensions used: BMI, CMOV, MODE64, SSE1, SSE2
CPU Generation: Haswell
```

And with:

```
File format and CPU architecture: Elf, X86_64
MODE64 (call)
CMOV (cmovge)
AVX (vmovd)
AVX2 (vinserti128)
NOVLX (vpxor)
BMI2 (shlx)
BMI (tzcnt)
Instruction set extensions used: AVX, AVX2, BMI, BMI2, CMOV, MODE64, NOVLX
CPU Generation: Unknown
```

The second build uses AVX and AVX2 (the `vmovd` and `vinserti128` vector instructions), BMI2 (`shlx`) and NOVLX (`vpxor`). The first one only gets as far as SSE2 and BMI. The htop in my nix store built with `-march=znver3` has the same extra instruction sets as the second one, so the flags are being applied. I did the same spot check on the Haskell packages.

Note: this only shows that the new instructions are in the binary. I make no guarantees about *observable* speed improvements.

= But compiling takes a really long time

Yes, this is terrible! I like to ride loose and free, so one glaring optimization is to skip checkPhase and installCheckPhase. Waiting for these (especially python install check phase) takes a really. Long. Time.

My first instinct was to set the check option:

```nix
config.doCheckByDefault = false;
```

But, disabling tests is not so trivial (e.g. this didn't work). I #link("https://discourse.nixos.org/t/globally-disabling-docheck/73016")[asked on discourse], and #link("https://discourse.nixos.org/t/globally-disabling-docheck/73016/2")[waffle8946] explained why: `doCheckByDefault = false` is already the default. Builders like `buildRustPackage` and `buildPythonPackage` sit on top of `mkDerivation` and set `doCheck = true` themselves, so whatever `mkDerivation` defaults to doesn't matter.

waffle8946 had the novel idea to unset `doCheck` and `doInstallCheck` in the shell instead. Nix decides whether to run checkPhase by looking at the `doCheck` *environment variable* while the build is running. So if an early phase runs `unset doCheck`, the check phase gets skipped no matter what the builder set. I ended up doing this in a custom phase to force that phase to #link("https://github.com/DieracDelta/flakes/blob/093a9b13244e0640d41bf58dc7eb5c819e8e5bf7/overlays/stdenv.nix?plain=1#L7")[always be run]:

```nix
# literally nuke all testphases because we ball
final: prev: {
  stdenv = prev.stdenv // {
    mkDerivation =
      fnOrAttrs:
      let
        disableChecks = ''
          unset doCheck
          unset doInstallCheck
        '';
        addDisablePhase =
          attrs:
          attrs
          // {
            prePhases = (attrs.prePhases or [ ]) ++ [ "disableChecksPhase" ];
            disableChecksPhase = disableChecks;
          };
      in
      if builtins.isFunction fnOrAttrs then
        prev.stdenv.mkDerivation (attrs: addDisablePhase (fnOrAttrs attrs))
      else
        prev.stdenv.mkDerivation (addDisablePhase fnOrAttrs);
  };
}
```

I also prepended the same `unset` to `preCheck` and `preInstallCheck`, since some packages disable or replace phases.

It turns out this remains difficult in the particular builders like buildPythonApplication, for two reasons:

- The python package sets grab their builders (and the stdenv they use) when nixpkgs constructs the interpreter's package set. So my stdenv overlay never reaches them, and I had to wrap `buildPythonPackage` and `buildPythonApplication` separately.
- Python has checks that *aren't* part of checkPhase or installCheckPhase. `pythonImportsCheck` (which imports your package to see if it's broken) and the runtime dependency check run on their own, so unsetting `doInstallCheck` doesn't touch them.

My first python overlay overrode the hooks' shell functions to do nothing:

```bash
unset doCheck
unset doInstallCheck
# Override Python-specific check phases to be no-ops
pytestCheckPhase() { :; }
pythonImportsCheckPhase() { :; }
```

These days I set the attributes directly instead (`doCheck = false`, `doInstallCheck = false`, `dontUsePythonImportsCheck = true`, `dontCheckRuntimeDeps = true`) and rebind the python builders to my stdenv.

Even then, a handful of packages build their test suite regardless of `doCheck` because they have their own switch for it. For example `vk-bootstrap` needs `-DVK_BOOTSTRAP_TEST=OFF`, `power-profiles-daemon` needs `-Dtests=false`, and `yubico-piv-tool` unconditionally does `add_subdirectory(tests)`, so I patch that line out. These have to be found one at a time.

= Adding `-pipe` and `-Wl,-z,pack-relative-relocs`

I also add two flags that Gentoo users like to set. #link("https://github.com/DieracDelta/flakes/blob/093a9b13244e0640d41bf58dc7eb5c819e8e5bf7/utility-functions.nix?plain=1#L52")[This] is where I add them globally:

- `-pipe` makes gcc pass data between its stages through pipes instead of temporary files. This means less disk IO, but it uses a bit more memory.
- `-Wl,-z,pack-relative-relocs` makes the linker store relative relocations in the compact `DT_RELR` format, which makes binaries a bit smaller.

Instead of an overlay, I set `config.replaceStdenv` to a stdenv whose `mkDerivationFromStdenv` appends `-pipe` to `NIX_CFLAGS_COMPILE` and the relocs flag to `NIX_CFLAGS_LINK`. One gotcha: always put them in `env`. If they're at the top level, you get conflicts with packages that later use `overrideAttrs` or structured attrs.

The relocs flag broke a few things, so they get skipped:

- GHC, which links with `ld.gold`, which doesn't support it. (I also strip it out before GHC compiles `Setup.hs`.)
- systemd
- OVMF, which builds EFI binaries
- `heroic-epic-integration` and `galaxy-dummy-service`, which are MinGW (Windows) builds

= Rebuilding the world finds rot

A fun side effect of building everything from source with no substituters: you find out which packages can't be built from source anymore. Normally you never notice, because the binary cache already has the output.

I wrote a script that walks a package set (e.g. top level or `pythonPackages`), and for each attribute runs:

```bash
nix-build --expr 'with import /path/to/local/nixpkgs/checkout {config.allowUnfree = true;}; $PKGNAME.src' --substituters ""
```

then sorts the failures into "the source is gone" and "the hash changed". The result was #link("https://github.com/NixOS/nixpkgs/issues/471645")[137 packages whose source 404s], #link("https://github.com/NixOS/nixpkgs/issues/471498")[a long list whose source hash no longer matches], and #link("https://github.com/NixOS/nixpkgs/issues/471115")[a bunch of python packages] in the same state. I fixed some of these upstream, mostly hash fixes for Maven, Composer and PyPI sources.

= Things I never got working

The original plan included a custom linker (mold, via `moldStdenv`) and LTO everywhere. I never got either to work, so neither is in my config.

= Practicality

Rebuilding the world while using the machine is only bearable if the builds get out of the way. I never want a build to max out memory or make my desktop laggy, so the nix daemon (and every build it runs) gets fenced in with systemd:

```nix
systemd.services.nix-daemon.serviceConfig = {
  # lowest-ish CPU priority, and only touch the disk when nothing else wants it
  Nice = lib.mkForce 15;
  IOSchedulingClass = lib.mkForce "idle";
  IOSchedulingPriority = lib.mkForce 7;
  # builds only get 20 of the 32 hardware threads
  AllowedCPUs = "0-19";
  MemoryHigh = "80G"; # Soft limit - throttles allocations when exceeded
  MemoryMax = "100G"; # Hard limit - OOM killer if exceeded
};

nix.settings.max-jobs = 6; # at most 6 derivations building at once
nix.settings.cores = 5;    # each build gets up to 5 threads (make -j5)
```

How this works:

- Builds run as children of `nix-daemon.service`, so the limits in `serviceConfig` cover all of the builds combined. (I also set `use-cgroups = true` so nix puts each build in its own cgroup underneath the daemon's.)
- `Nice = 15` means builds only get CPU time that I'm not using. `AllowedCPUs = "0-19"` goes further and pins builds to 20 of the 5950x's 32 threads, so there are always 12 threads that a build can never touch.
- `MemoryHigh` is the soft limit. Once builds use more than 80G, the kernel starts reclaiming their memory aggressively and slows down their allocations. `MemoryMax` is the hard limit: past 100G, the OOM killer kills one of the builds, so my browser survives. I have 128GB of RAM, so this leaves roughly 28GB for everything else no matter what is building.
- `max-jobs` and `cores` set the parallelism: at most 6 derivations at once, each with up to 5 threads. That's 30 threads of work competing for the 20 allowed ones, which keeps the allowed CPUs busy without spawning an absurd number of compiler processes. Each compiler process is what eats memory, so this also keeps memory use from spiking in the first place.

Note: `IOSchedulingClass = "idle"` turned out to do nothing on my machine. Both of my NVMe drives use the `none` I/O scheduler, and only BFQ honors I/O classes. What actually works is capping the build's write bandwidth per drive with `IOWriteBandwidthMax`:

```nix
systemd.services.nix-daemon.serviceConfig.IOWriteBandwidthMax = [
  "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNJ0X121581J 20M"
  "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_23501N800832 20M"
];
```

I do the opposite for the things I need to be snappy while a build is running (ssh, sunshine for remote desktop, eternal terminal):

```nix
systemd.services.eternal-terminal.serviceConfig = {
  Nice = -10;
  CPUWeight = 1000;
  IOSchedulingPriority = 0;
  IOWeight = 1000;
};
```

And as a last line of defense, `earlyoom` kills the biggest process if the whole machine runs low on memory anyway.
