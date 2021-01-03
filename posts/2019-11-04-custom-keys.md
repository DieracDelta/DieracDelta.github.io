---
author:
  name: "Justin Restivo"
date: 2019-11-04
linktitle: custom keybinds
title: custom keybinds
type:
- post
- posts
weight: 10
series:
- Justin's Life
aliases:
- /blog/custom\_keybinds
---

### how to bind custom usb keyboard keys using eudev on gentoo###

This is mostly for my own sanity if I ever want to edit this again. Basically if you have a custom usb device and want to bind the keys, follow these instructions on gentoo running eudev (process is similar for systemd):

- make a /etc/udev/hwdb directory (for systemd; ignore otherwise)
- look in /lib/udev/hwdb for instructions (for gentoo)

There is a mapping between scancodes and keycodes. Scancodes are what the device (usbkeyboard) make and they're mapped by udev to keycodes. View usb devices and the scancodes they generate via evtest. The "value" is the scancode in hex. What you have to do is (1) DO NOT follow the instructions because udev doesn't look in /etc/udev/hwdb. Instead it will work with /dev/udev/hwdb. Find your keyboard (in my case, by searching "Alienware")  in the 60-keyboards.hwdb file. Then append rules in there. The syntax is `KEYBOARD_KEY_$HEX_SYM=$CODE`. A concrete example I use is `KEYBOARD_KEY_92=p`. Then, to reload, run `sudo udevadm hwdb --update` and then `sudo udevadm trigger --verbose --sysname-match="event*"`.

