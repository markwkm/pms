#!/bin/sh
#
#  cross_ppc_default.sh
#
#  This is a wrapper script which sets up the cross-compile environment.
#  It is meant to call 'compile_default_count.sh'
#
#

# Set up environmental vars
export ARCH=x86_64
export CROSS_COMPILE=${ARCH}-unknown-linux-gnu-
export PATH=$PATH:/var/crosstool/${ARCH}-unknown-linux-gnu/gcc-3.4.0-glibc-2.3.2/bin
# Override the standard ccache
export CCACHE_DIR=/var/spool/ccache.${ARCH}

#
# Rename the alternate config for the script.
#
# Remove ones left by wget.  -f doesn't complain if no such file.
#rm -f alternate.configs.${ARCH}.[1-9]
#CONFIG=`ls alternate.configs.${ARCH}*`
#  There should be only one configuration file
#mv $CONFIG alternate.configs.${ARCH}

# Run the filter.
chmod +x compile_default_count.sh
./compile_default_count.sh

# Remove the filter so there is none the next time.
# -f doesn't complain if no such file.
rm -f compile_default_count.sh
#rm -f alternate.configs.${ARCH}*
