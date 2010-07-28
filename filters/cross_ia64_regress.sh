#!/bin/sh
#

export ARCH=ia64 
export CROSS_COMPILE=ia64-unknown-linux-gnu-
export PATH=$PATH:/var/crosstool/ia64/tools/bin
# Override the standard ccache
export CCACHE_DIR=/var/spool/ccache.ia64

chmod +x compregress_fast.sh
./compregress_fast.sh

rm compregress_fast.sh
rm -f alternate.configs.${ARCH}*
