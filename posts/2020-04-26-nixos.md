---
author:
  name: "Justin Restivo"
date: 2020-04-26
linktitle: An honest review of NixOS
title: An honest review of NixOS
type:
- post
- posts
weight: 10
series:
- Justin's Life
aliases:
- /blog/nixos
---

The overarching goal of this post comes in four main parts:

- Chronicle my experiences with linux and motivate nixos.
- Explain why I recently switched to nixos.
- Discuss what I have tried to do with nixos, and the varying degrees of success I've reached (and complain about the pain points).
- Was it worthwhile to switch?

# Past experiences #

I've been using Linux on and off for the past 7 years. My progression in terms of distros has been:

- 2013-2016: Dissatisfied with windows, I found out about Linux and installed Ubuntu 11.10/12.04/12.10 onto three different computers. I stayed on Linux for about 2 years and a half years. I was mostly enthralled by compiz and the speed of Linux compared to the disastrous Windows Vista on my relatively weak hardware. Remember Unity? I loved that and gnome 3. I didn't dig into how the package manager or command line worked since the Ubuntu Software Center existed. But then, I upgraded my hardware, making it more or less unnecessary to have Linux.
- 2016-2017: I stayed on Windows 8.1 for about a year after I upgraded my laptop and no longer required Linux for the speed it offered. I wasn't coding outside of basic python/java and so didn't notice any difference in development tools.
- 2017-2018: With the help of a friend, I hopped off windows and onto Arch Linux. I actually learned bash, how window management worked with i3wm, and started to use vim/spacemacs for development. This was when I really started to appreciate how much of a haven Linux can be for developers. However, I eventually stopped updating, and lo and behold I started having package dependency problems (most of which came from the blackarch repos that I had added). Moreover, I was frustrated by how little I understood the package manager. I wanted to set things up manually instead.
- 2018-2019: My hardware starting having issues again, and when I switched systems, I distro hopped to Gentoo (and to dwm), as it took what I liked most about arch (good documentation and bleeding edge packages). This was a great learning experience (although it is debatable how useful the skills I picked up were), and I got to compile the Linux kernel, learn about useflags/masks in conjunction with portage, and to use openrc as an alternative init manager. However, as I continued to use Gentoo, I encountered more and more issues with updating. As of December 2019, I hadn't updated for 6 months, and had over 100 dependency conflicts. I had a couple of options at this point. I could either unemerge over 100 packages (including Xorg), mask over 100 packages, or reinstall. Even though I had my configuration files detailing what I did and didn't have installed and how I had configured the Linux kernel, recompiling everything seemed like a massive waste of time. I wouldn't be learning anything and it was just going to be a long wait. However, I really liked the flexibility of being on a source-based distribution (for only specific packages and the kernel), and didn't really want to veer away from Gentoo. I could do without the init manager, as I didn't really notice anything different between systemd and openrc. I was also tired of maintaining my dwm fork and had switched to herbstluftwm which had a non-negligable memory leak at the time. Remember, I couldn't upgrade it without masking a large amount of packages. At this point I was doing most of my development in docker to get up-to-date packages, which is far from ideal.
- I briefly installed Bedrock Linux to let myself install packages from other distros in the hope that this would let me update things. This felt like a major hack which I wouldn't recommend. The concept is cool, but in practice it got messy really quickly. I needed something that took this concept of installing differently packaged versions of the same package and did it better.

This leads us to my decision to switch off Gentoo and onto NixOS.

# Why did I switch? #

I really like developing in docker. Whenever I needed to develop a project, I'd write a Dockerfile for it that had the relevant toolchain installed, then spin up a docker image with a mounted shared volume between this docker container and my host. This made development really easy, and I liked the idea of having a sand-boxed dev environment on a per project basis a lot. However, it does have a couple of pain points:

- Memory usage is through the roof! The final docker container in my last project was over 50 gigs. Let's not even mention the cached 30 steps on the way to that final version (this was so unmanageable I had to disable caching). Every time I wanted to upgrade the toolchain by touching the Dockerfile, I'd have to wait ages for everything to rebuild, and my memory usage was still through the roof. Docker really doesn't care about how much memory it uses and pruning unused images/containers still left hundreds of gigs of used storage in `/var/docker` for no apparent reason. That being said, due to the consistent dev environment it provided, at the time I thought it was the best alternative I had.
- Although I start out consistent, it was often hard to remember if I'd modified the docker container I was running. It got to a point where every time I made a change to the toolchain, I would go back to the docker file and make changes. This was a super slow dev cycle without caching.

The other really nice thing about docker is that you can use it to deploy projects to servers very easily. I've done this for my filehost and this blog on a digitalocean droplet.

To summarize, I had several things I wanted in my life:

- The flexibility of a source-based distro and the ability to compile packages myself.
- Not getting screwed over by not updating for 6 months. E.g. a reliable package manager that can update almost effortlessly.
- Bleeding edge packages available.
- Fast, lean, sandboxed environments to develop in that are easy to deploy.

This is what I wanted in my next distro, and the reasons why I've switched to NixOS. NixOS checks the boxes for all of these requirements, and goes above and beyond in almost every thing I was looking for.

First, NixOS is source-based. As a result, you can build any package from source if you so desire. However, it also has a binary cache online, so for packages where you don't care too much about compiling, you can just pull them down. So this gives you instant package installation when you need them while also the flexibility of compiling from source.

Next, consider the docker issues when I began to modify the toolchain. Docker forces you to define its container in a linear sequence of steps, although not all builds are linear. Additionally tooling changes inside of the container put docker into an inconsistent state (e.g. I can't reproduce it unless I change the Dockerfile). NixOS does this better in a rather unique way.

To understand how, let's look at the nix package manager. The general gist of how this works is that each package ends up in its own `/nix/store/$HASH$PACKAGE_NAME`. It looks and feels like a chroot (also notice, this makes it trivial to have multiple versions of the same package installed!). Nix only put that package into that chroot. To handle dependencies, given an input list of dependencies, nix constructs a set of corresponding read-only dependency chroots and modifies path and library loading variables appropriately. This results in a really nice modularization of components and isolation that makes packages very easy to manage. Additionally, updates are easy, since there cannot be any conflicts of the sort I encountered on gentoo due to the unique nix-store per package. 

What makes this really powerful is that I can pin packages to specific versions, which makes each nix build exactly as reproducible as any docker file. The real kicker is that the state (package configuration) is always well defined based on a couple of configuration files. How is this really powerful? I've committed my configuration files to github. If my harddrive dies or I need to reinstall, all I need to do is clone my config files, partition the disk, then tell Nix to rebuild based on my config files. And I'm back to my old system with exactly the same packages installed in exactly the same way.

Note that I did mention that nix is bleeding edge. I should clarify this further by saying it is optionally close to bleeding edge. Similar to debian and debian sid, there are separate channels of varying degrees of stability to choose between (and you can mix and match installed packages between the two at the same time!)

Given the way things are constructed, one would guess that this could naturally extend to work wonders for dev environments. If I need a specific version of clang built with a specific commit of llvm ONLY for one project, I can create a `shell.nix` file saying that this is what I want. I can then open a shell using `nix-shell shell.nix`. Nix will then install this custom clang and llvm in separate nix stores then enter me into a shell with them on my path! This feels exactly like docker except the containerization is built into the distro so I don't need to use that extra layer of abstraction.

Nix expands on this concept with `lorri`. Essentially, I can `lorri init` in a directory, specify the dependencies for the project in my project root's `shell.nix`, and then `direnv allow` and add a zsh (or bash) hook to my zsh/bashrc file. Then, when I `cd` into the directory, my path is automatically changed to include the custom dependencies! Just like docker! Except, since the build is written in nix's config language, it's not linear and so each step isn't cached. Instead all the dependencies are built in their own `/nix/store/*` and then just added to the path. So modifying things like path variables or libraries required doesn't result in massive amounts of rebuilding like in docker or gigabytes of wasted storage. I'm thinking of it as containerization on steroids. It's so much nicer and more convenient than using a docker container. Also, as a sidenote, `emacs` will recognize a project-wide `shell.nix` file and appropriately change its paths to include the relevant toolchains (including language servers!).

Let's take a step back. NixOS is just part of the picture. There's the aforementioned package manager, nix. NixOS comes with the package manager but also extends it to manage things like your kernel and systemd services. And finally, there is NixOps and hydra, which I'll talk about in a separate blog post, but basically extend this further in a similar way to deploying with docker and kubernetes.

One other sidenote is that the nix package manager is cross platform. It can be installed to get those project-wide dependency resolutions on other linux distributions like debian or gentoo and on macos (although this requires more effort due to recent security updates).

Finally, I wanted to elaborate a bit on how easy it is to modify packages (as this is a source based distro). It's really easy. Similarly to gentoo, nix has this concept of an overlay. You can either modify attributes of an existing package or define your own new package pretty easily by feeding in a github link to the source and some build instructions. I will say that out of the box, nix is super smart about how to build packages, so often times it's very easy to build the package itself. For example, since rootbar which uses ninja and nix knows how to build packages built with ninja, it only takes a few lines to explain the build process with the nix language.

TLDR; Nix is able to solve most of my problems with the distros I've used in the past. It's able to replace docker for me in development, for a given state defined in a configuration file, always build and maintain in a deterministic way a bijection to a resulting linux and package configuration, give me a choice between stability and bleeding edge, and be source based enough for me to compile custom packages.

TODO I'd also like to talk about how I build rebuild the entire system but most stuff is cached and tha's why it's in consistent state

TODO talk about language

# My NixOS Adventures #

I've tried to do a couple of very not-very-well supported things with NixOS. Some of them were easy, but some of them weren't.

## My desktop ##

This was non-trivial because I chose wayland instead of Xorg to be my desktop. This is not as well supported because wayland is still relatively new. That being said, I've got a working version of sway, pywal, rootbar, and wofi. Writing their config files was about as straightforward as usual. The only caveat was that I had to define those in my dotfiles for nix, then has nix copy them to `/etc` so they would be used as expected (TODO elaborate on this).

## My shell ##

I used zsh. The next step on my agenda was to port over all the zshell niceties including the addons like syntax-highlighting, fzf, and auto-suggestions. Luckily, these all existed as options in home-manager that I could just enable. Home-manager is a set of nix-stores and a friendly surrounding environment for user specific applications such as their shell. I moved my aliases into a nix expressions, and copied the rest of my zshrc into a file to be sourced by my zshrc. Nix then generated my zshrc for me, and placed it in the right spot (e.g. it became another part of the state nix controlled).

## cli applications ##

This was also the issue of bringing up cli applications like neovim, emacs, and tmux. Tmux worked out of the box with home-manager. I was able to source my `.tmux.conf` and have nix generate a tmux config file based on that. Same idea worked for vim outside of plugin management. Instead of using plug, I let home-maanger grab the plugins. I haven't figured out CoC because at this point I've moved on to emacs and don't really use vim for anything but quick edits of files requiring root access to modify.

### emacs ###

I'll do another blog post on why I switched from vim to emacs and how I replicated my vim workflow in emacs. However, the configuration parts relevant to nix are three-fold:

- The default "cutting edge" version of emacs is 26.3. This is too old for me (emacs 28 includes massive speed improvements for json parsing and thus language server speed) so I had to change to using the community overlay from [this](https://github.com/nix-community/emacs-overlay) bleeding edge repo, which recompiles upon every new commit.
- Home-manager integrates nicely with emacs and provides plenty of wrappers/options. The only downside is that emacs can't write to `~/.emacs.d/` and every change to a config file requires rebuilding the home-manager state.

## custom overlays ##

### deepfrier ###

This was written mainly to see how easy it would be to write an overlay in python with a couple of nontrivial dependencies. I had to add in a dependency on a imagemagick overlay (that I wrote) that added flags to compile imagemagick with liquid rescale. This was surprisingly easy to do.

### zathura + pywal ###

I wanted to wrap the existing zathura package to generate a config on startup based on colors from pywal. This works well.

## Projects ##

I've had the opportunity to try a couple of different languages out with these `nix.shell` expressions to manage project-specific dependencies. Here are the results:

### Rust ###

I'm a big fan of Rust, and it was important to me that Rust ran smoothly on Nix. Although much of the rust tooling (cargo, rustup) doesn't work, the mozilla overlay does a fantastic job of making the same tooling options available through their Rust overlay.

I built a [filehost](https://github.com/DieracDelta/filehost_rust) using Rust and Rocket.rs. This was really easy and I had no problems installing packages, building, or developing with RLS on emacs.

It's also worth mentioning that even the cross compiler stuff works well. For example, a kernel written in rust, [Tock](https://github.com/tock/tock/blob/master/shell.nix), showcases how easy it is to grab a 32 bit cross compiling toolchain for RISC-V both for gcc and rustc/llvm.

### Ocaml ###

My job requires ocaml and while I've been able to install opam outside of nix, the nix support for ocaml is very lacking. I wasn't able to install the packages I needed (although this seems to be somewhat of a convoluted process). That being said, the `ocaml-lsp` language server works great when installed with opam outide of nix. I have it working both with coc-nvim and emacs on nix.

### Python ###

Python works great--you can build packages in to your custom build using your `shell.nix` similarly to venvs.


### systemd-boot ###

This can be a pain to enable on some distros, but on NixOS, it's as simple as setting the `boot.loader.systemd-boot.enable` flag to true.

### docker ###

Docker is as easy as toggling a flag or two as well. And after I had it enabled, it worked as easily as on other distros. It was easier than on Gentoo, as I didn't have to recompile the kernel and add a bunch of extra kernel modules.


## GPU Passthrough ##

I ended up doing a GPU passthrough to a windows virtual machine and since I only had a single monitor, I also enabled streaming with looking glass. My GPUs were a Radeon RX 5600 XT and 550X. I passed the faster card (5600 XT) to the windows VM. Note that currently (april 2019), this card suffers from the navi reset bug and requires a kernel patch. This kernel patch doesn't help a huge amount, and the computer will freeze if you restart the vm too many times. The performance also wasn't great (I'm getting 30 fps on the Witcher 3 on low settings). However, I haven't gotten to applying optimizations like CPU pinnings and huge pages.

Getting to this workable state was much easier on NixOS than doing the equivalent exercise on a fairly versatile distribution like arch or gentoo. There are already some good blog posts about this, but the gist of it for me lived in a single [file](https://github.com/DieracDelta/nix_home_manager_configs/blob/master/dotfiles/gpu_passthrough.nix).

What's happening? I get the latest kernel:

`boot.kernelPackages = pkgs.linuxPackages_latest;`

Then, I enabled AMD-Vi for virtualization in my motherboard's BIOS, then added the AMD `iommu` instruction flag to the kernel boot parameters. Again, this was just a flag:

`boot.kernelParams = [ "amd_iommu=on" ];`

Next, I enabled the relevant virtualization kernel modules:

`boot.kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];`

I enabled Libvirtd with some more flags:

```
  virtualisation.libvirtd.enable = true;
  users.groups.libvirtd.members = [ "root" "jrestivo"];
```

Next, I added in the equivalent of a modprobe configuration file:

```
boot.extraModprobeConfig ="options vfio-pci ids=1002:731f,1002:ab38";
```

Finally, I had to patch for the navi bug, which also is incredibly easy. I'm able to just specify the kernel patch path:

```
 boot.kernelPatches = [ { name = "navi reset patch"; patch = ./reset_bug_patch.patch; } ];
```

Nix will recompile the kernel for you locally with the patch with no effort on your part. The last thing I needed to do was configure my `qemu.conf` file with `virtualization.libvirtd.qemuVerbatimConfig`. At this point I was basically done--all I had to do was rebuild Nix, reboot to incorporate the new kernel and kernel parameters, then I could go use virt-manager to set up my virtual machine and start windows. At that point I had to install some drivers and make devices as described on the arch wiki per usual.

The ground breaking thing about using nix for this was that I could easily enable and disable the virtual machine by just rebuilding my system without the VFIO config file. Also, everything lives in one place, which makes it much more difficult to forget the procedure that got me to this point. I can see all the config files I had to modify to get this working, and thanks to the nix documentation, it's very simple to see exactly what they do/pattern match them with the arch wiki page on the topic.


## Was it worthwhile to switch? ##


