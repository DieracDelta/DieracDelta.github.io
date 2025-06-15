#import "../lib.typ": *
#show: schema.with("page")

#title[Switching to Nix Flakes]
#date[2021-01-09]
#author[Justin Restivo]

= Motivation

I switched to nix flakes over christmas vacation. It could do with some better
mechanics, but in general it's pretty great and I feel much more comfortable
with the stability and flexibility of my system than I did before.

Nix the package manager has rolling release on all it's packages. It uses a
channel system and a release system. This means that for each release,
there's a `stable` and `unstable` channel. The `stable` channel is probably
not broken, but has older packages. This generally works quite well if you
live on stable. You can also mix and match `stable` and `unstable` packages.
However, this is poor for long term stability and reproducibility. Given that
this is the entire point of using Nix as a package manager, this seem bad.

Flakes is the solution to this problem. In a similar fashion to npm, flakes
will generate a lock file. Building your system with the lock file will
guarantee the *same* system down to the commit hash. This is essentially the
main motivating factor for me.

= Mechanics

== Getting nix flakes

Switching flakes was nearly trivial, even if you're using home-manager. The
first step is to install flakes on your system. This is done by including
the following in your `configuration.nix`:

```nix
  nix = {
      package = pkgs.nixUnstable;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
     };
```

This moves the `nix` package manager to unstable. Then, add `nixFlakes` to the
list of packages to install flakes.

== Enabling flakes

This part is simple enough; it's outlined on the
#link("https://nixos.wiki/wiki/Flakes")[wiki]. The input list will probably include
the stable, unstable, and home-manager channels, and the output list can
contain only your `configuration.nix` and `home.nix` (for home-manager)
nixos modules, as outlined #link("https://github.com/nix-community/home-manager#nix-flakes")[on the home-manager readme].

Before building your system, flakes requires that the directory you're building
from be a git repo, and that all files being used in the build be staged.

Then you can build your system by running (in the repo root directory):

```bash
sudo nixos-rebuild switch --flake $HOST_NAME
```

Note that since we're using flakes, flakes will create a `flake.lock` file
that will allow us to build the repo on any machine *down to the commit used*.

Note what we're already getting with very little expended effort:

- a monolithic repo for both our *user* and *system* configuration. I was
  already doing this pre-flakes, but I had to run two separate build commands.
  The fact that I can manage them both without having to deal explicitly
  with mutliple channels is neat.
- identical builds proccesses. Of course, compiler non-determinism cannot be
  avoided and service management is sometimes sketchy,
  but in general everything up to that is the same. Specifically, the
  commit hash of the repos used *and* the way the repos are built
  *will not change*. This is a long winded way of saying
  *if it built and ran on one machine targeting amd64,
  it will also build on all other machines targeting amd64*.

== nixflk

The initial flakes are pretty cool, but there are some nifty abstractions that
one can add on top. I ended up using #link("https://github.com/nrdxp/nixflk")[nixflks]
and my friend's #link("https://github.com/gytis-ivaskevicius/nixfiles")[fork] of
nixflks as my starting ground. I'll talk more to the fork, since those are the
abstractions I've been using. My dotfiles are
#link("https://github.com/DieracDelta/flakes")[here].

The basic structure I settled with looks like this:

```
├── flake.nix
├── hosts
│   ├── default.nix
│   ├── desktop.nix
│   ├── laptop.nix
│   ├── hw
│   │   ├── desktop.nix
│   │   ├── laptop.nix
│   │   └── shared.nix
│   └── shared
│       ├── apps.nix
│       ├── default.nix
│       ├── dotfiles
│       ├── home.nix
│       ├── misc.nix
│       └── services.nix
└── overlays
    ├── deepfry
    └── imagemagick
```

The idea is that I have two computers: a desktop and a laptop. They have:

- different hardware
- same dotfiles (window manager, text editor, services)
- same applications installed
- same overlays

As a result, the `hosts/default.nix` chooses a host based on hostname
(e.g. either laptop or desktop). This includes `$HOSTNAME.nix` file, which
gets the relevant hardware and includes the entirety of the `shared` directory.

This means that I'm able to keep different `hw` and other small differences
separate, while avoiding code duplication with the `shared` directory. The
`shared` directory includes my dotfiles, common services (like zerotier),
my dev tools, etc. This generally feels super clean and gives me a flexible
way to manage both my machines.

== gotchas

One of the slight gotchas for doing this is the inclusion of a
`hardware-configuration.nix` file. I copied over most of it to the `hw`
directory. However, you'll need to go onto `nixpkgs`, grab the #link("https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/scan/not-detected.nix")[`not-detected.nix`],
and cut and paste that into the common hardware file.

The whole having to stage the files you use is really annoying. Whenever I added
a new file, I'd build, scratch my head, then realize that I had forgot to stage
it.

Error messages could definitely be a bit more forgiving...

Sometimes the cache gets into an inconsistent state and fails immediately
when trying to build. The remedy is to make a trivial change
(perhaps add a newline) to the `flake.nix` and rebuild. This was also pretty
annoying.

== cachix

The caching for unstable doesn't work very well. As a result, I'm sometimes
stuck compiling on my laptop. This is not ideal since my laptop is old and
not powerful. To solve this, I can compile programs on my desktop, push the
results very easily to cachix, and then pull them down on my laptop
(using the same lock file). This is pretty nice.

== other perks

Another perk of using flakes is that you can effortlessly import and use
others flakes by listing them as inputs.
