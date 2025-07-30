#import "../lib.typ": *
#show: schema.with("page")

#title[Debugging Nix Expressions]
#date[2025-07-30]
#author[Justin Restivo]

I wanted to discuss some features of Nix that I don't see discussed very often related to debugging.

= `-L` flag

I think this is still undocumented, but running any nix command with the `-L` flag will print the logs to stdout.

= Debugging flakes

Each derivation of a flake comes with a nix shell. That is:

```
nix develop .#packages.x86_64-linux.mypackage --ignore-env
```

will drop you into what is `nix` env in your local directory without the sandboxing effects.

You can then run each of the phases (note: this is still impure):

```
$configurePhase
$buildPhase
$checkPhase
```

This can be useful for initially debugging nix expressions, and is #link("https://nix.dev/manual/nix/2.30/command-ref/new-cli/nix3-develop")[straight out of the nix manual]

= Inspecting the output

As mentioned in this #link("https://jade.fyi/blog/debugging-nix-package-building/")[awesome blog post], #link("https://nixos.org/manual/nixpkgs/stable/#breakpointhook")[`breakpointHook`] and #link("https://github.com/Mic92/cntr")[`cntr`] are useful for inspecting build outputs.

In particular, on Linux, inserting `breakpointHook` to the `*inputs` for *any* phase will run the phase to completion or error, then provide a command for dropping into a shell containing the artifacts of the phase.

This is of course useful for debugging the `buildPhase`, but also can be used in other phases. For example, to inspect `checkPhase` output, inserting `breakpointHook` into the `checkInputs` will pause the build at the end of the checkPhase. This isn't documented, but is quite useful.

One subtlety: how does cntr fit into this? It turns out there's another undocumented hook called `breakpointHookCntr` which will use `cntr` to drop into the derivation and allow for inspection *with* dev tooling that is already on the PATH (though, it will have to be tooling that is in the nix store). Note that the given `cntr` command will have to be run as root (I'm not sure how to give the `CAP_SYS_CHROOT` capability to a normal user).
