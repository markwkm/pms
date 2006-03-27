#!/bin/sh
#
#  max_config_count.sh
#
#  This is a wrapper script which sets up the environment.
#  It is meant to call 'compile_count.sh'
#
#

# Set up environmental vars
export ARCH=i386 
export OLDCONFIG_ONLY=1
export NO_PRINT_CONFIGS=1
export CONFIG_URL=http://www.osdl.org/archive/plm/filters/config/alternate.configs.i386.max.030925
#export CROSS_COMPILE=powerpc-750-linux-gnu-
#export PATH=/var/crosstool-0.22/powerpc-750/tools/bin:$PATH

#
# Rename the alternate config for the script.
#
# Remove ones left by wget.  -f doesn't complain if no such file.
#  There should be only one configuration file
rm -f alternate.configs.${ARCH}.[1-9]
mv alternate.configs.${ARCH}.max alternate.configs.${ARCH}

# Run the filter.
chmod +x compile_count.sh
./compile_count.sh

# Remove the filter so there is none the next time.
# -f doesn't complain if no such file.
rm -f compile_count.sh
rm -f alternate.configs.${ARCH}*
