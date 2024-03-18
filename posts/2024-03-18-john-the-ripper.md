---
author:
  name: "Justin Restivo"
date: 2024-03-18
title: "Using John the Ripper"
---

This is mostly for my own reference.

Suppose we have a locked pdf. To extract the hash (that we then crack using john), run `pdf2john.pl`. On nix, this is packaged under John. That is:

```
nix build nixpkgs#john && ./result/bin/pdf2john.pl my.pdf >> hash
```

Then we can use John to extract the hash. This works like:

```
nix run nixpkgs#john -- --wordlist=myWordlist hash
```

Wordlist is a newline delimited file of possible passwords to try. This will output the result of John into a temporary file (though, Im not sure where this is).

To print the passphrase that unlocks the hash (and thereby the pdf):

```
nix run nixpkgs#john -- --show hash
```
