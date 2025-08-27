#import "../lib.typ": *
#show: schema.with("page")

#title[Haskell Development]
#date[2025-08-27]
#author[Justin Restivo]

This is meant to be an aggregation of unintuitive things I've encountered when developing with haskell.

= Generating docs

One would like to run a local hoogle instance to avoid noise. How does one do this?

```bash
# generate html documentation into ./haddocks
cabal haddock-project --hoogle --all --internal --foreign-libraries --keep-temp-files
# generate hoogle database from project
hoogle generate --local=haddocks/ --database=project.hoo
hoogle server -p 8910 --local --host 0.0.0.0 -n --database project.hoo
```

This will create a local hoogle database viewable at `0.0.0.0:8910`. Note that the `--database` flag can be left out to write the database in `$HOME/.hoogle`.

I didn't use `nix` for this because if I do run `doHoogle`, then the database doesn't include all the packages I need. I'll elaborate on how I set up the nix shell in the future.
