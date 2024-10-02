---
author:
  name: "Justin Restivo"
date: 2024-10-02
title: "Checking myself in HIBP"
---

# Motivation

I recently looked up my email in [HIBP](https://haveibeenpwned.com/)'s database. Turns out my email had been hit in a few leaks over the past couple years. The natural next step was to check for my password in their database.

# Checking my credentials

They suggest downloading their password database using their .net tool. However, I couldn't be bothered to learn their tool. There's another toolk that serves the same function [here](https://github.com/ptechofficial/hibp-python-downloader). In case that goes private or is deleted I made a fork [here](https://github.com/DieracDelta/hibp-python-downloader).

Running this tool (`./script.py`) will download a ~40GB text file of `hash_suffix:num_occurrences`. If I want to check my password, I need to generate a sha1 hash. There's a bunch of tools to do this (sha1sum, openssl etc), but I used rhash. `rg -i $(echo -n "$MY_PASSWORD" | rhash --sha1 --simple - | awk '{print $1}' | cut -c 6-) hashed_passwords.txt`  will do the trick. The inner command will output a hash, but then we only care about the second 35 characters (the first 5 are used in [lookup](https://haveibeenpwned.com/API/v3#:~:text=Each%20password%20is%20stored%20as,a%20UTF%2D8%20encoded%20password.) and then dropped), which is the reason for the cut invocation.
