#!/bin/bash
PATH=$PATH:/home/export/src/setup-scripts/build/tmp-angstrom_v2012_05-eglibc/sysroots/x86_64-linux/usr/bin:/home/export/src/setup-scripts/build/tmp-angstrom_v2012_05-eglibc/sysroots/x86_64-linux/usr/bin/armv7a-angstrom-linux-gnueabi
echo $PATH
. ./setvars.sh
cd build/beagle-linux
make CROSS_COMPILE=arm-angstrom-linux-gnueabi-
