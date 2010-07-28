#!/bin/sh
#

export ARCH=ppc 
export CROSS_COMPILE=powerpc-750-linux-gnu-
export PATH=$PATH:/var/crosstool/powerpc-750/tools/bin
# Override the standard ccache
export CCACHE_DIR=/var/spool/ccache.ppc

chmod +x compregress_ppc.sh
./compregress_ppc.sh -mPLM

rm compregress_ppc.sh
rm -f alternate.configs.${ARCH}*
