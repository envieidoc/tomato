# Copyright 2001-2015, Broadcom Corporation
# All Rights Reserved.
#
# THIS SOFTWARE IS OFFERED "AS IS", AND BROADCOM GRANTS NO WARRANTIES OF ANY
# KIND, EXPRESS OR IMPLIED, BY STATUTE, COMMUNICATION OR OTHERWISE.  BROADCOM
# SPECIFICALLY DISCLAIMS ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A SPECIFIC PURPOSE OR NONINFRINGEMENT CONCERNING THIS SOFTWARE
#

There are multiple directories provided here. The release directory
contains the router source package. The uClibc directory contains the source
for uClibc. The binary tools required to build are provided as a
convenience.

To build the router:
 o Follow the instructions in the tools/ directory to install the toolchain
 o Ensure the tools in the release/tools directory are in your path
 o cd release/src
 o type 'make'

This will create a parallel directory to src called image that contains the
final image.

## How to compile Tomato Shibby on Ubuntu 12.04.5 LTS (for Asus RT-N66U)

```bash
$ git clone git://repo.or.cz/tomato.git
$ cd tomato
$ git checkout tomato-shibby-RT-AC
$ sudo ln -s full/path/to/tomato/tools/brcm /opt
$ export PATH=${PATH}:/opt/brcm/hndtools-mipsel-linux/bin:/opt/brcm/hndtools-mipsel-uclibc/bin:/mnt/a/projects/tomato/release/tools
$ git describe --tags
ShibbyRT-N_095-624-ga45b4d6
# you will need to install some dependencies from apt repository, apart of these,
# this version requires automake1.14 and automake1.13 (just compile and install from sources)
# this version has the branch tomato-shibby-RT-N merged into tomato-shibby-RT-AC
$ cd release/src-rt
$ make help # check which build do you want to build
$ make V1=9999 V2=test-r2 r64z
# V1 and V2 arbitrary (version) numbers
# r64z -> build RT-N66u build AIO
```

