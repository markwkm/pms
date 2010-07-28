#!/bin/sh
#

export ARCH=x86_64 
export CROSS_COMPILE=x86_64-unknown-linux-gnu-
export PATH=$PATH:/var/crosstool/x86_64-unknown-linux-gnu/gcc-3.3.2-glibc-2.3.2/bin
# Override the standard ccache
export CCACHE_DIR=/var/spool/ccache.x86_64

chmod +x compregress_fast.sh
./compregress_fast.sh

rm compregress_fast.sh
rm -f alternate.configs.${ARCH}*
