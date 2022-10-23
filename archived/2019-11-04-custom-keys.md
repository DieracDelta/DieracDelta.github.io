---
author:
  name: "Justin Restivo"
date: 2019-11-04
linktitle: Custom Keybinds on Gentoo
title: Custom Keybinds on Gentoo
type:
- post
- posts
weight: 10
series:
- Justin's Life
aliases:
- /blog/custom\_keybinds
---

# how to bind custom usb keyboard keys using eudev on gentoo #

This is mostly for my own sanity if I ever want to edit this again. Basically if you have a custom usb device and want to bind the keys, follow these instructions on gentoo running eudev (process is similar for systemd):

- make a /etc/udev/hwdb directory (for systemd; ignore otherwise)
- look in /lib/udev/hwdb for instructions (for gentoo)

There is a mapping between scancodes and keycodes. Scancodes are what the device (usbkeyboard) generate and they're mapped by udev to keycodes.

To view usb devices and the scancodes they generate, run evtest. The "value" is the scancode in hex. Find the keyboard (in my case, by searching "Alienware")  in the 60-keyboards.hwdb file. Then append rules in there. The syntax is `KEYBOARD_KEY_$HEX_SYM=$CODE`. A concrete example I use is `KEYBOARD_KEY_92=p`. Then, to reload, run `udevadm hwdb --update` and then `udevadm trigger --verbose --sysname-match="event*"`. Only works on gentoo.

