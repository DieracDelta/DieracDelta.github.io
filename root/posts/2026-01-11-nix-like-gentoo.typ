#import "../lib.typ": *
#show: schema.with("page")

#title[Running NixOS like Gentoo]
#date[2026-01-11]
#author[Justin Restivo]

I used to daily drive Gentoo before NixOS. Nix's value add was that it had the nice parts of Gentoo (the useflags, customizability, and from-source packages) while retaining the usability of something like Ubuntu. Since I've come to Nix, I've wanted to run it like Gentoo: all the useflags, mega optimization, custom linker, etc. Here's a writeup of how I've made rebuilding the world every week with all the #link("bells and whistles")[https://www.shlomifish.org/humour/by-others/funroll-loops/Gentoo-is-Rice.html] of Gentoo ferrari practical.

= -march=native (Arch specific optimizations)

Caveat: while you *can* do this with `-march=native`, I think that's against the idea of Nix. It's definitionally impure, and I love Nix's purity. Instead, I will choose the architecture of my 5950x processor's `znver3`.

To do this, I had to take three steps. First: enable the ability to build for znver3:

```
nix.settings.system-features = [
  // ..
  "gccarch-znver3"
];
```

This *enables* nix to build programs for znver3. Since I'm already on a znver3 machine, this enabled me to target the machine I'm running on.

Next, I enabled the relevant flags by setting `mtune` and `march` config options when importing nixpkgs:

```nix
import nixpkgs {
  // "my current system is x86_64-linux"
  localSystem = "x86_64-linux";
  // I want to build for znver3 microarch
  hostPlatform = {
    system = "x86_64-linux";
    gcc.arch = "znver3";
    gcc.tune = "znver3";
    gcc.abi = "64";
  };
  // I want any compilers I build to target znver3 microarch
  targetPlatform = {
    system = "x86_64-linux";
    gcc.arch = "znver3";
    gcc.tune = "znver3";
    gcc.abi = "64";
  };

}

```

We can take a similar action on the GPU. Nvidia has a config option to say which cudacompute capability to use:

```nix
import nixpkgs {
  // ..
  cudaSupport = true;
  cudaCapabilities = [ "8.9" ];
}
```

This allows me to emit optimized cuda code for my specific card (4090).

= But compiling takes a really long time

Yes, this is terrible! I like to ride loose and free, so one glaring optimization is checkPhase and the installCheckPhase to run. Waiting for these (especially python install check phase) takes a really. Long. Time.

My first instinct was to set the check option:

```nix
config.doCheckByDefault = false;
```

But, disabling tests is not so trivial (e.g. this didn't work). #link("https://discourse.nixos.org/t/globally-disabling-docheck/73016")[waffle8946] had the novel idea to unset `doCheck` and `doInstallCheck`. I ended up doing this in a custom phase to force that phase to #link("https://github.com/DieracDelta/flakes/blob/093a9b13244e0640d41bf58dc7eb5c819e8e5bf7/overlays/stdenv.nix?plain=1#L7")[always be run].

TODO explain

It turns out this remains difficult in the particular builders like buildPythonApplication, because they introduce their own custom "check" boolean like TODO I forget why this was hard

= Adding `-pipe` and `-Wl,-z,pack-relative-relocs`

TODO talk about #link("https://github.com/DieracDelta/flakes/blob/093a9b13244e0640d41bf58dc7eb5c819e8e5bf7/utility-functions.nix?plain=1#L52")[this]

= More `march=native`

TODO zig, rust

= A custom linker (moldStdenv)

= lto

= Practicality

TODO niceness, ioniceness, systemd service changes, tc
