---
author:
  name: "Justin Restivo"
date: 2021-02-15
title: Deploying a Rust filehost to Oracle Cloud with Rocket.rs, Nixos, Flakes, Sops, and Deploy-rs
---

# Motivation #

I've manually deploy a filehost to a digital ocean VPS in the past. There were
several pain points.

Services: setting up nginx and a systemd service for my filehost was a pain. I had to
edit a bunch of configuration files every time I wanted to make a change.
Testing was hard since as I had to restart nginx and systemd manually at every
step.

Authentication: I wanted to authenticate my filehost. I ended up just using a
plaintext "key" that I committed to my github. Anyone could have hacked me.

Deploying every time I made a change was painful. I would ssh into the vps
where I didn't have any of my dev tools, make changes in nano, then see if things
worked. I was missing my shell and editor. I could have set those things up,
but really I ought to have been developing locally, but I didn't have a way to
easily test without deploying.

Certificates: I had to ssh in every 3 months and figure out how to use
letsencrypt to generate certs. This was annoying.

Updating/System Maintenance: I had to ssh in and update. Sometimes this broke libraries
or services and that I would have to manually fix.

# Prerequisites #

I'm assuming some rudimentary knowledge of nix flakes and rust. This is intended
as an example of how far flakes can go.

# Rust Filehost #

The goal is to deploy a clone of `ix.io`. The functionality looks like this:

`|❯ echo "hello world" | curl -F 'f:1=<-' -F 'read:1=2' ix.io
http://ix.io/M3M `

This will make a text file containing "hello world" available at `ix.io/M3M`.
This is convenient for sharing small snippets of code.

We would like something similar:

```
|❯ echo "hello world" | post_code
$SOME_UNIQUE_URL
```

Rocket.rs is as rust framework that can be used to spin up a set of restful endpoints.
For a filehost, there should be two endpoints: a POST endpoint and a GET endpoint.
The POST will allow us to post code, and the GET will allow us to retrieve code.

The full repository is [here](image), though I followed [this](https://github.com/SergioBenitez/Rocket/tree/master/examples/pastebin) tutorial pretty closely. There's nothing too novel going on. I've got a GET endpoint:

```rust
#[get("/code/view/<id>", format = "text/html")]
fn get_code(id: String) -> NamedFile {
    NamedFile::open(format!("{}{}{}", get_storage_path(), CODE_PATH, id)).unwrap()
}
```

This just opens up a preexisting file at some CODE_PATH.
Similarly, POST checks auth, then generates a unique filename, then writes to a file.

Nothing too fancy going on so far.

# Flakifying the Rust Filehost #

The build should be completely reproducible. That is to say,
regardless of the machine the filehost is build,
the output binary should build exactly the same. Rust's lock files
provide this for all Rust packages. What remains is to ensure that all builds use 
the same version of the compiler, cargo, and any other dependencies required by every build.
These extras come through using Nix Flakes. `Naersk` may be used to convert
Cargo lock file into something that Nix can understand and build. For the rust toolchain,
instead of relying on rustup, which is not declarative (it's a binary host),
we use [rust-overlay](https://github.com/oxalica/rust-overlay).

Let's start by building up the Rust flake. As with any flake,
first we define our `inputs`:

```nix
inputs = {
    utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nmattia/naersk";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };
  ```
```
```
These define Naersk and rust-overlay's hosts. Flake-utils contains a bunch of
helper functions to build on multiple system architectures.

Next, define flake outputs:
```nix
outputs = { self, nixpkgs, utils, naersk, rust-overlay }:
  utils.lib.eachDefaultSystem (system:
    # TODO fill in
  )
```

This is a function with the named flake inputs as arguments (attributes of `inputs`).
The `utils.lib.eachDefaultSystem` can be thought of as a function with signature `System -> Outputs`.
`eachDefaultSystem` produces a bunch of standard outputs.

Rocket.rs requires nightly rust and cargo. So, the config must tell Nix to
use nightly rust and cargo. These obtain these from the rust overlay input:

```nix
 let pkgs = import nixpkgs {
         inherit system;
         overlays = [
           rust-overlay.overlay
           (self: super: {
             rustc = self.latest.rustChannels.nightly.rust;
             cargo = self.latest.rustChannels.nightly.rust;
           })
         ];
       };
```

This imports nixpkgs, and replaces rustc and cargo with their nightly counterpart.
Note that we don't care very much about versions, since nix flakes will pick a
version and place it in its lock file.

Next, we need to tell `Naersk` to use these nightly versions of packages, as
this is a requirement of `rocket.rs`:

```nix
 naersk-lib = naersk.lib."${system}".override {
        cargo = pkgs.cargo;
        rustc = pkgs.rustc;
      };
    in
```

This overrides the `cargo` and `rustc` attributes of `naersk-lib` tool
use their nightly counterparts.

Finally, we define several outputs:

```nix
      packages.filehost = naersk-lib.buildPackage {
        pname = "filehost";
        root = ./.;
        /*buildInputs = with pkgs; [];*/
      };
      defaultPackage = packages.filehost;

      apps.filehost = utils.lib.mkApp {
        drv = packages.filehost;
      };
      defaultApp = apps.filehost;

      devShell = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [ rustc cargo ];
      };
    });
```

`packages.filehost` defines a filehost package to be our current repo.
`defaultPackage`  and `defaultApp` are fairly self explanatory. `devShell`
defines a shell accessible by `nix develop` that gives access to nightly
rustc and cargo so that the filehost may be develop without having to fight
with nix (really we only want to use nix for deployment).

Now, recall that function `eachDefaultSystem` earlier. It now has enough information to generate
these described outputs for four different os/architecture combos. We can observe them 
by running `nix flake show` in the top level directory of our repo. It gets us this nice colored tree:

```
git+file:///home/jrestivo/fun/filehost?ref=master&rev=3f43864845d8106275548d24c1b19204447674f2
├───apps
│   ├───aarch64-linux
│   │   └───filehost: app
│   ├───i686-linux
│   │   └───filehost: app
│   ├───x86_64-darwin
│   │   └───filehost: app
│   └───x86_64-linux
│       └───filehost: app
├───defaultApp
│   ├───aarch64-linux: app
│   ├───i686-linux: app
│   ├───x86_64-darwin: app
│   └───x86_64-linux: app
├───defaultPackage
│   ├───aarch64-linux: package 'filehost-0.1.0'
│   ├───i686-linux: package 'filehost-0.1.0'
│   ├───x86_64-darwin: package 'filehost-0.1.0'
│   └───x86_64-linux: package 'filehost-0.1.0'
├───devShell
│   ├───aarch64-linux: development environment 'nix-shell'
│   ├───i686-linux: development environment 'nix-shell'
│   ├───x86_64-darwin: development environment 'nix-shell'
│   └───x86_64-linux: development environment 'nix-shell'
└───packages
    ├───aarch64-linux
    │   └───filehost: package 'filehost-0.1.0'
    ├───i686-linux
    │   └───filehost: package 'filehost-0.1.0'
    ├───x86_64-darwin
    │   └───filehost: package 'filehost-0.1.0'
    └───x86_64-linux
        └───filehost: package 'filehost-0.1.0'
```

Before building the package, cargo must build the package to pin cargo package dependencies.

```bash
nix develop && cargo build --release
```

This results in a `Cargo.lock`.  To tell nix about this lock file, it must be `git add`-ed.
Now running `nix build .`, will produce the `x86_64-linux` system's version of the pacakge built. 
And, we get a `flake.lock`. This, similar to Cargo's lockfile, will tie down
every single dependency used by the flake to the commit.
It's about as reproducible as possible sans compiler nondeterminism.

In fact, CI may be added to build and cache build binaries and artifacts 
to be pulled locally later by any matching system. This is particularly easy with Github Actions.
This style of automation will be discussed further in another blog post.

# Authentication and Completing the filehost#

Before we deploy, we want to make sure there is at least a bit of authentication
for our app. A simple way to do this is by passing in an environment
variable containing a secret when the app is started. Then, upon post
request, check that the key passed in with the path parameters of the post
request match that key. Note that if this parameter passing is done over https (which we
will force later on) [then the secret key shall be encrypted](https://stackoverflow.com/questions/4143196/is-get-data-also-encrypted-in-https#:~:text=10%20Answers&text=The%20entire%20request%20is%20encrypted,the%20destination%20address%20and%20port.&text=The%20entire%20response%20is%20also,intercept%20any%20part%20of%20it).

I won't go through the rust code to do this, but in order to test out the file host,
(it should be fairly self explanatory), but clone [here](https://github.com/DieracDelta/filehost_rust)
and `nix build .`. Then running:

`STORAGE_PATH=$SOME_PATH SECRET_PASSWORD=$SOME_SECRET_PASSWORD ./result/bin/filehost`

will run the filehost locally, using `SECRET_PASSWORD` as the method of authentication
and `SOME_PATH` as the path to store files at. Using `tmp` seems easy as a start.

To test the auth, one can define the following zsh functions:

```bash
function post_code {
        SECRET_PASSWORD="secret_password"
        INPUT_UNESCAPED=$(cat)
        INPUT=''${INPUT_UNESCAPED//\\/\\\\}
        echo -n "https://filehost.restivo.me/code/view/"$(echo -n '{"key":"'$SECRET_PASSWORD'","src":"'$(echo $INPUT | base64)'"}' | curl -X POST https://filehost.restivo.me/code/post -H 'Content-Type: application/json' --data @- | jq -r '.link') | xclip -selection clipboard
}
```

Example usage could be `echo "hello world" | post_code`. 

Unpacking what's going on:

- The secret password used for auth is defined in plaintext. This is not good practice, and will be fixed later on with sops.
- `INPUT_UNESCAPED` is stdin. In the example `hello world`.
- `INPUT` escapes `\` in `INPUT_UNESCAPED` so the slashes will be preserved during the post request.
- The last line creates creates the post request. The post endpoint url is `filehost.restivo.me/code/post/`. 
  Parameters are sent in with json in an encrypted html header in a json format.
  The `key` is provided in plaintext, and the `$INPUT` is base64encoded for easier transmission. `--data @-` specifies to provide post data from stdin. The result of the post is piped to `jq` which parses the resulting json and retrieves the `link` attribute. This is then copied onto the clipboard (assuming the use of X server).

The data is encrypted using https, so this is "somewhat" secure. It fits the goal of basic authentication and DDOS prevention without being fancy.

At this point, a working `filehost` flake has been written, and includes authentication.
Now we may deploy.

# Secret Management #

The first question here is "how can secrets such as a passphrase be stored on nix?"
A popular solution, independent of nix, is to use mozilla's [`sops`](https://github.com/mozilla/sops)
tool. [Nix-sops](https://github.com/Mic92/sops-nix) wraps this super easily.
I'm not going to reiterate the README, but will summarize in a few sentences.

Starting with a basic flakes system configuration file, `sops-nix` may be added
an input. Then, `sops` can be put into the module list in the server (host's)
module list. Finally, the server's ssh keys can be converted to
pgp keys. Add a `devshell` and set `SOPS_PGP_FP` to a list of private PGP keys,
`nix develop`, then run `sops secrets.yaml`. This `sops` command allows decrypted editing
of a a yaml list of secrets that is encrypted with the listed of private pgp keys on write.
So, secrets may be added, such as the filehost secret key, then committed to the
configuration git repo and pushed to a git host (in this case github).



# Systemd Service #


, our filehost service ought to run automatically, out of
the box. To do this, we write a [nixos module](https://github.com/DieracDelta/flakes/blob/flakes/custom_modules/filehost.nix)
that will automatically run our filehost.

# Nginx reverse proxy #

# Preparing the Oracle Instance #

# Deployment #



