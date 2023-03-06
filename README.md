# PS2 Memory Card Utils

## What's this?

A few utilities to help with management of PlayStation2 Memory Cards.

The main part is the [mymc](http://www.csclub.uwaterloo.ca:11068/mymc/)
utility, which does brunt of the PS2 Memory Card management[^1].

However, [SD2PSX](https://sd2psx.net/) doesn't readily work with it.

The reason is that SD2PSX uses raw 512 byte sectors, whereas mymc uses
528 byte sectors (data + 12B checksum + 4B padding).

To that end I wrote two small utils (sectorpad.rb and sectorstrip.rb)
that allow you to Hobbit the format[^2].

## How to use

Say that you got yourself shiny new `Card1-1.mcd` thanks to SD2PSX[^3].

``` sh
$ ruby sectorpad.rb Card1-1.mcd Card1-1.ps2
+ Input size OK (RAW 8MB card with 512B sectors)
+ Done.

$ python2 mymc/mymc.py Card1-1.ps2 ls
rwx--d----+----      11 2023-02-26 12:49:52 .
-wx--d----+--H-       0 2022-10-24 05:49:31 ..
rwx--d----+----       6 2023-02-26 12:47:17 APPS
rwx--d----+----       5 2022-11-05 02:32:04 BOOT
rwx--d----+----       9 2022-11-05 02:31:59 SYS-CONF
rwxp-d----+----      11 2022-11-05 02:31:45 BIEXEC-SYSTEM
rwxp-d----+----       6 2022-11-05 02:31:47 BEEXEC-SYSTEM
rwxp-d----+----       7 2022-11-05 02:31:50 BAEXEC-SYSTEM
rwxp-d----+----       5 2022-11-05 02:31:52 BCEXEC-SYSTEM
rwx--d-------H-       4 2023-02-26 12:57:13 BEDATA-SYSTEM
rwx--d----+----       6 2023-02-26 12:49:56 OPL

# other mymc commands here (adding / extracting files, etc)

$ ruby sectorstrip.rb Card1-1.ps2 Card1-1.mcd
+ This is padded 8MB card, cool.
+ Done.
```

## How to create a new card

``` sh
$ python2 mymc.py blank.ps2 format

# rest of commands (if you wish)

$ ruby sectorstrip.rb blank.ps2 blank.mcd
+ This is padded 8MB card, cool.
+ Done.
```

## How to extract & repackage existing card

Please note: signed/encrypted elf files are specific to the one card.
It won't be possible to shuffle them to a different card. That said,
looks like sd2psx uses the same ID for all cards. :-)

Also note: extracting and repackaging will break file linking, resulting
in more space wasted. You might not care, though. Especially if you use this
for sd2psx.

``` sh
$ ruby sectorpad.rb Card1-1.mcd Card1-1.ps2
+ Input size OK (RAW 8MB card with 512B sectors)
+ Done.

$ ruby dump-card.rb Card1-1.ps2 dump
+ Extracting contents ...
  > mkdir BOOT
    + extract icon.sys
    + extract BOOT.ELF
    + extract BOOT.icn
  > mkdir SYS-CONF
    + extract ICON.SYS
    + extract FMCB_CFG.ELF
    + extract SYSCONF.ICN
    + extract USBD.IRX
    + extract USBHDFSD.IRX
    + extract FREEMCB.CNF
  > mkdir BIEXEC-SYSTEM
    + extract ICON.SYS
    + extract osdsys.elf
    + extract osd130.elf
    + extract DEV9.IRX
    + extract osd110.elf
    + extract ATAD.IRX
    + extract osdmain.elf
    + extract HDDLOAD.IRX
    + extract FMCB.ICN
  > mkdir BAEXEC-SYSTEM
    + extract ICON.SYS
    + extract osd130.elf
    + extract osd120.elf
    + extract osdmain.elf
    + extract FMCB.ICN
  > mkdir BCEXEC-SYSTEM
    + extract ICON.SYS
    + extract osdmain.elf
    + extract FMCB.ICN
  > mkdir APPS
    + extract FMCBapps.icn
    + extract icon.sys
  > mkdir BEEXEC-SYSTEM
    + extract ICON.SYS
    + extract osd130.elf
    + extract osdmain.elf
    + extract FMCB.ICN
+ All done.

# tweak the 'dump' directory as you like

$ ruby card-from-dir.rb c.ps2 dump
+ Formatting card "c.ps2" ...
+ Adding contents ...
> mkdir "BOOT"
> add "BOOT/icon.sys"
> add "BOOT/BOOT.ELF"
> add "BOOT/BOOT.icn"
> mkdir "SYS-CONF"
> add "SYS-CONF/ICON.SYS"
> add "SYS-CONF/FMCB_CFG.ELF"
> add "SYS-CONF/SYSCONF.ICN"
> add "SYS-CONF/USBD.IRX"
> add "SYS-CONF/USBHDFSD.IRX"
> add "SYS-CONF/FREEMCB.CNF"
> mkdir "BIEXEC-SYSTEM"
> add "BIEXEC-SYSTEM/ICON.SYS"
> add "BIEXEC-SYSTEM/osdsys.elf"
> add "BIEXEC-SYSTEM/osd130.elf"
> add "BIEXEC-SYSTEM/DEV9.IRX"
> add "BIEXEC-SYSTEM/osd110.elf"
> add "BIEXEC-SYSTEM/ATAD.IRX"
> add "BIEXEC-SYSTEM/osdmain.elf"
> add "BIEXEC-SYSTEM/HDDLOAD.IRX"
> add "BIEXEC-SYSTEM/FMCB.ICN"
> mkdir "BAEXEC-SYSTEM"
> add "BAEXEC-SYSTEM/ICON.SYS"
> add "BAEXEC-SYSTEM/osd130.elf"
> add "BAEXEC-SYSTEM/osd120.elf"
> add "BAEXEC-SYSTEM/osdmain.elf"
> add "BAEXEC-SYSTEM/FMCB.ICN"
> mkdir "BCEXEC-SYSTEM"
> add "BCEXEC-SYSTEM/ICON.SYS"
> add "BCEXEC-SYSTEM/osdmain.elf"
> add "BCEXEC-SYSTEM/FMCB.ICN"
> mkdir "APPS"
> add "APPS/FMCBapps.icn"
> add "APPS/icon.sys"
> mkdir "BEEXEC-SYSTEM"
> add "BEEXEC-SYSTEM/ICON.SYS"
> add "BEEXEC-SYSTEM/osd130.elf"
> add "BEEXEC-SYSTEM/osdmain.elf"
> add "BEEXEC-SYSTEM/FMCB.ICN"
+ All done.

$ ruby sectorstrip.rb c.ps2 c.mcd
+ This is padded 8MB card, cool.
+ Done.

# c.mcd is now ready to rock.
```

## License

The `sector*.rb` are licensed under GPLv2.

The `mymc` directory is in public domain.

[^1]: Don't reinvent the wheel, if you don't have to, right?
[^2]: There and back again.
[^3]: I'm using already populated card (not an empty one) to make things
less boring.
