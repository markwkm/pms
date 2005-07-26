#!/bin/sh
#
# AUTHORS:
#	Original script by John Cherry <cherry@osdl.org>
#	PLM port by Nathan Dabney <smurf@osdl.org>
#       Some cleanups by Roberto Nibali <ratz@drugphish.ch>
#
# kernstats - Kernel build stats
#
# kernstats performs the following things during a build:
#   make mrproper (unless using supplied .config) 
#   make (oldconfig|defconfig|allyesconfig|allmodconfig) 
#   make dep
#   make bzImage (continues to completion even if there are errors)
#   make modules (continues to completion even if there are errors)
#   make clean
#   makes individual components/directories to isloate the source of errors
#   prints out a summary of the failures
#   prints out a list of errors and a list of warnings
#
# For additional information, the following files are left behind:
#   <kernel version>.<config method>.bzimage.txt
#   <kernel version>.<config method>.modules.txt
#   <kernel version>.<dir where build failed>.txt (could be many)
#   <kernel version>.failure.summary
#   <kernel version>.warning.summary
#   <kernel version>.error.list
#   <kernel version>.warning.list
#
#	Version		Comments
#	1.1.3		For 2.4 builds, the arch specific list of
#			omissions needed to include fs/openpromfs and 
#			drivers/macintosh (only useful at SPARC and PPC)
#	1.1.4		Only do make dep for 2.4.x kernels
#	1.1.5		Added link to test results
#       1.1.6		Fixed typo which kept scsi drivers from being
#                       built while building individual modules.
#	1.1.7		Save original configuration and build that again
#			after other builds.  Fixed warning strings.
#       1.1.8           2.4 builds from scratch were broken after applying
#                       1.1.7 changes.  This is fixed.  
#                       Fixed up the individual module build lists for
#		        2.4/2.5 differences and to include the upper-level
#                       builds as the last step (i.e. /drivers/scsi).
# 	1.1.9		Save and restore the LC_ALL environmental variable
#			so that it can LC_ALL can be set to different
#			languages without breaking things like grep.
#       1.1.10 		Added some kludges to get ia64 builds going.
#                       At some point, the allmodconfig setup should
#                       work and this can be removed.
#
#	1.2.0		Makefile format changed.  Could not confirm targets
#			by grepping the Makefile.  Fixed this and included
#			fixes for alternate config options for ia64.
#	1.2.1		Lots of little cleanups
#	1.3.0		misc cleanup - Roberto Nibali <ratz@drugphish.ch>
#			Added allyesconfig builds
#			Pulled a lot of redundant code into routines.
#			Changed alternate.configs to alternate.configs.<arch>
#
COMPREGRESS_VERSION="1.3.0"
#

# Set this to the number of CPUs you want to use when building the kernel
# to autodetect try: CPU_MAX=`grep -c cpu /proc/cpuinfo`
# Comment this line out to avoid forcing -j to make
# The -j# will be CPU_MAX+1 when in PLM mode
# declare CPU_MAX=`grep -c processor /proc/cpuinfo`

#
# For a cross-compile, set environmental variables:
#    ARCH-the architecture as represented in the 'arch' directory of the source
#    CROSS_COMPILE-The prefix prepended to the gcc executible
#    PATH-To include path to cross-compiler.
#
# There are no more user configurable settings 
#

declare -r LC_ALL=C
declare -r HOME=`pwd -P`
declare    MY_ARCH=`uname -m | sed -e 's/i686/i386/'`
declare    MAKEOPT="KBUILD_VERBOSE=0 -ki"
declare    MAKECONFIGOPT="KBUILD_VERBOSE=0"
declare    MAKEDEPOPT=""
declare    NOARCH=""
declare    CLEANUP=""
declare    ALT_CONFIGS=0

#
# If a cross-compile is setup, MY_ARCH needs to be set from the
# environment variable rather than uname.
#
if [ ! -z $ARCH ]; then
	MY_ARCH=$ARCH
        # For the 2.4 kernels ARCH and CROSS_COMPILE failed unless explicit options
        MAKEOPT="$MAKEOPT ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE"
        MAKECONFIGOPT="$MAKECONFIGOPT ARCH=$ARCH"
        MAKEDEPOPT="ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE"
fi

#
# Default mode is dev.  If environment variable is set, use that
# instead.
#
MODE=PLM
#if [ ! -z $COMPREGRESS_MODE ]; then
	#MODE=$COMPREGRESS_MODE
#fi

#
# This should be the only way to leave this script
#
leavecleanly() {
	rm -f ${CLEANUP}
	exit 0
}
trap leavecleanly INT TERM QUIT

#
# Select target build.  vmlinux or vmlinux.gz for ia64 and
# bzImage for other builds (including ia32)
#
BZIMAGE="vmlinux"
if [ $MY_ARCH == ia64 ]; then
	if [ -f Makefile ]; then
		if [ `grep -c vmlinux.gz: Makefile` != 0 ]; then
			BZIMAGE=vmlinux.gz
		fi
	fi
else
	BZIMAGE=bzImage
fi

echo "
Welcome to the [ Compile Regression on ${MY_ARCH} ] Filter $COMPREGRESS_VERSION
( http://developer.osdl.org/cherry/compile/compregress.sh )
"

if [ $MODE == PLM ]; then
echo "

This filter generates a list of warnings and errors in the kernel source.
A PASS will be reported if there are no errors found, regardless of the 
presence of warning conditions.  It will be uncommon for this to PASS
on kernels that support allmodconfig.  It is nice to dream though.

The primary purpose of this report is to show WHERE the error and warning
messages are being generated.
"
fi

# Send a line to the result log
log () {
	[ $MODE == PLM ] && echo $@ >> $HOME/result.filter
	echo $@
}

#
# Set up .config to be the original .config.  If there was no
# original .config, set it to the default config options
#
setup_oldconfig() {
	for x in 1 2 3 4 5 6 7 8 9 10; do
		STR="\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n ${STR}"
	done
  
	make mrproper > /dev/null 2>&1
	test -f oldconfig-config && cp oldconfig-config .config

	echo -e $STR | make $MAKECONFIGOPT oldconfig &> /dev/null
	echo -e $STR | make $MAKECONFIGOPT oldconfig &> /dev/null
	if [ "$BASE_VERSION" == 2.4 ]; then 
		make $MAKEDEPOPT dep >> $KERNEL_OLDCONFIG 2>&1
	fi
}

#
# If an alternate.config.<arch> file exists, append it to the current
# .config and run "make oldconfig".  This will make the alternate
# configs override those in the .config file.
#
alt_configs() {
	if [ -f ../alternate.configs.$MY_ARCH ]; then
		mv ../alternate.configs.$MY_ARCH .
	fi
	if [ -f alternate.configs.$MY_ARCH ]; then
		ALT_CONFIGS=1
		TMPFILE=`mktemp $VERSION.XXXXXX`
		cat .config alternate.configs.$MY_ARCH > $TMPFILE
		mv $TMPFILE .config		
		make $MAKECONFIGOPT oldconfig > /dev/null 2>&1
	fi
}

print_alt_configs() {
	if [ -f alternate.configs.$MY_ARCH ]; then
		printf "\nAlternate configurations used in allyesconfig/allmodconfig builds\n"
		cat alternate.configs.$MY_ARCH
	fi
}

#
# CONFIG_MODVERSIONS is a option that allows building with modules that
# were built for other kernels.  This is not needed for these builds and
# has the potential to spew useless warnings/errors, so we force it off.
#
no_modversions() {
	TMPFILE=`mktemp $VERSION.XXXXXX`
	sed 's/CONFIG_MODVERSIONS=y/\# CONFIG_MODVERSIONS is not set/' < .config > $TMPFILE
	mv $TMPFILE .config
}

print_counts() {
	WARN_COUNT=`egrep " warning: " $1 | sort -u | wc -l`
	ERROR_COUNT=`egrep " Error " $1 | sort -u | wc -l`
	egrep " Error " $1 >> $ERROR_LIST
	egrep " warning: " $1 >> $WARN_LIST
	printf "%s warnings, %s errors\n" $WARN_COUNT $ERROR_COUNT
}

# Clean out results from potential previous runs (debug testing...)
[ $MODE == PLM ] && rm -f $HOME/result.filter $HOME/ERROR

#
# Pre-test versioning information
#
echo Version information for host [ `hostname` ]
echo " gcc:   " `${CROSS_COMPILE}gcc -v 2>&1 |grep 'gcc version'|cut -d\  -f3`
echo " patch: " `patch -v | grep patch | cut -d\  -f2`
echo

if [ $MODE == PLM ]; then
	echo "md5sum of available source [.patch .gz .bz2]"
	[ -n "`ls plm-*.patch 2> /dev/null`" ] && md5sum plm-*.patch
	[ -n "`ls *.gz 2> /dev/null`" ] && md5sum *.gz
	[ -n "`ls *.bz2 2> /dev/null`" ] && md5sum *.bz2
	echo
fi

#
# TEST: Does the linux directory exist?
#
if [ $MODE == PLM ] && [ ! -d linux ]; then
	log RESULT: FAIL
	log RESULT-DETAIL: Missing linux directory
	leavecleanly
fi

[ ! -f Makefile ] && [ -d linux ] && cd linux

#
# TEST: Did the patch program report an error
#
if [ -f patch.error ]; then
	log RESULT: FAIL
	log RESULT-DETAIL: Patch did not apply cleanly, cannot build
	leavecleanly
fi

#
# we need to find out of this kernel supports "defconfig" as a make target
#
if make -n $MAKECONFIGOPT defconfig > /dev/null 2>&1 ; then
	HAS_DEFCONFIG=1
	echo "This kernel supports 'defconfig' (including)"
else
	HAS_DEFCONFIG=0
	echo "This kernel does NOT support 'defconfig' (skipping)"
fi

# 
# Check for build target "allyesconfig"
#
if make -n $MAKECONFIGOPT allyesconfig > /dev/null 2>&1 ; then
	HAS_ALLYESCONFIG=1
	echo "This kernel supports 'allyesconfig' (including)"
else
	HAS_ALLYESCONFIG=0
	echo "This kernel does NOT support 'allyesconfig' (skipping)"
fi

# 
# Check for build target "allmodconfig"
#
if make -n $MAKECONFIGOPT allmodconfig > /dev/null 2>&1 ; then
	HAS_ALLMODCONFIG=1
	echo "This kernel supports 'allmodconfig' (including)"
else
	HAS_ALLMODCONFIG=0
	echo "This kernel does NOT support 'allmodconfig' (skipping)"
fi

#
# Check for build target "oldconfig"
#
if make -n $MAKECONFIGOPT oldconfig > /dev/null 2>&1 ; then
	HAS_OLDCONFIG=1
else
	HAS_OLDCONFIG=0
fi

#
# Make sure we have at least one of the required configure methods
#
if [ $HAS_DEFCONFIG == 0 ] && 
   [ $HAS_ALLYESCONFIG == 0 ] && 
   [ $HAS_ALLMODCONFIG == 0 ] && 
   [ $HAS_OLDCONFIG == 0 ]; then 
	echo "no .config present and oldconfig is not supported either."
	log RESULT: FAIL
	log RESULT-DETAIL: No known config methods available
	leavecleanly
fi

#
# Disable HAS_OLDCONFIG when it is not needed
#
if [ $HAS_OLDCONFIG == 1 ] && [ $HAS_DEFCONFIG == 1 ] && [ ! -f .config ]; then
	HAS_OLDCONFIG=0
fi

#
# Let the user know when we are using both oldconfig and defconfig and why
#
if [ $HAS_OLDCONFIG == 1 ] && [ $HAS_DEFCONFIG == 1 ]; then
	printf "\nAfter all other builds, a build will be done with the existing .config\n"
	cp -f .config oldconfig-config
fi

echo

# Shortcut for find options ;-)
FOPT="-maxdepth 1 -mindepth 1 -type d"

#
# Build the list of archs we want to ignore
#
cd arch
ARCHS=`find ${FOPT} | grep -v $MY_ARCH | sed -e 's/\.\///'`
cd ..

for x in $ARCHS; do
	NOARCH="${NOARCH} -e /${x}"
done

#
# Grab the lists of directories to build
#
if [ "$BASE_VERSION" == 2.4 ]; then 
	test -d fs && FS_LIST=`find fs ${FOPT} | grep -v -e openpromfs -e devpts $NOARCH | sort`
	test -d drivers && DRIVER_LIST=`find drivers ${FOPT} | grep -v -e macintosh -e scsi -e video -e message ${NOARCH}`
	MISC_LIST="arch/${MY_ARCH} crypto icp lib net security sound usr drivers/message/fusion drivers/message/i2o"
else
	test -d fs && FS_LIST=`find fs ${FOPT} | grep -v -e openpromfs $NOARCH | sort`
	test -d drivers && DRIVER_LIST=`find drivers ${FOPT} | grep -v -e macintosh -e scsi -e video ${NOARCH}`
	MISC_LIST="arch/${MY_ARCH} crypto icp lib net security sound usr"
fi
test -d drivers/scsi && SCSI_LIST=`find drivers/scsi ${FOPT} | grep -v -e aic7xxx_old -e dpt -e "scsi$" ${NOARCH} | sort`
test -d drivers/video && VIDEO_LIST=`find drivers/video ${FOPT} | grep -v -e "video$" ${NOARCH} | sort`
test -d sound && SOUND_LIST=`find sound ${FOPT} | grep -v ${NOARCH} | sort`
DRIVER_LIST=`echo ${DRIVER_LIST} ${SCSI_LIST} ${VIDEO_LIST} | sort`
MISC_LIST="arch/${MY_ARCH} crypto icp lib net security sound usr"

#
# Compile the master list of directories to build
#
DIRECTORIES_LIST=`echo $FS_LIST $DRIVER_LIST $SOUND_LIST $MISC_LIST | sort -u`
DIRECTORIES_LIST="$DIRECTORIES_LIST fs drivers/video drivers/scsi drivers/net"

#
# Get kernel version from the top level Makefile
#
#set -- $(sed -e 's%^\(.*\) = \(.*\)$%\2%;4q' < Makefile)
#VERSION="$1.$2.$3$4"
TMP=`sed -n '1p' < Makefile`
set $TMP
VERSION=$3
TMP=`sed -n '2p' < Makefile`
set $TMP
VERSION=$VERSION.$3
BASE_VERSION=$VERSION
TMP=`sed -n '3p' < Makefile`
set $TMP
VERSION=$VERSION.$3
TMP=`sed -n '4p' < Makefile`
set $TMP
VERSION=$VERSION$3


#
# Construct output files
#
KERNEL_DEFCONFIG="$VERSION.defconfig.$BZIMAGE.txt"
KERNEL_OLDCONFIG="$VERSION.oldconfig.$BZIMAGE.txt"
KERNEL_ALLMOD_OUTPUT="$VERSION.allmodconfig.$BZIMAGE.txt"
MODULES_ALLMOD_OUTPUT="$VERSION.allmodconfig.modules.txt"
KERNEL_ALLYES_OUTPUT="$VERSION.allyesconfig.$BZIMAGE.txt"
MODULES_ALLYES_OUTPUT="$VERSION.allyesconfig.modules.txt"
MODULES_DEFCONFIG="$VERSION.defconfig.modules.txt"
MODULES_OLDCONFIG="$VERSION.oldconfig.modules.txt"
DIRECTORY_BUILDS="$VERSION.log"
FAIL_SUMMARY="$VERSION.failure.summary"
WARN_SUMMARY="$VERSION.warning.summary"
ERROR_LIST="$VERSION.error.list"
WARN_LIST="$VERSION.warning.list"

rm -f $KERNEL_DEFCONFIG $KERNEL_OLDCONFIG $KERNEL_ALLMOD_OUTPUT
rm -f $MODULES_ALLMOD_OUTPUT $MODULES_DEFCONFIG $MODULES_OLDCONFIG
rm -f $DIRECTORY_BUILDS* $FAIL_SUMMARY $WARN_SUMMARY $ERROR_LIST $WARN_LIST

printf "Kernel version: %s\n" $VERSION
printf "\n" > $FAIL_SUMMARY
printf "\n" > $WARN_SUMMARY

#
# Generate the make optimizations
#
if [ -n $CPU_MAX ]; then
	[ $MODE == PLM ] && let "CPU_MAX=$CPU_MAX + 1"
	MAKEOPT="$MAKEOPT -j$CPU_MAX"
fi

#
# Build kernel and modules (both defconfig and allmodconfig)
#
printf "Kernel build: \n"

if [ $HAS_DEFCONFIG == 1 ]; then
	printf "   Making $BZIMAGE (defconfig): "
	make mrproper > /dev/null 2>&1
	make $MAKECONFIGOPT defconfig > $KERNEL_DEFCONFIG 2>&1
#	alt_configs
	if [ "$BASE_VERSION" == 2.4 ]; then 
		make $MAKEDEPOPT dep >> $KERNEL_DEFCONFIG 2>&1
	fi
	make $MAKEOPT $BZIMAGE >> $KERNEL_DEFCONFIG 2>&1
	print_counts $KERNEL_DEFCONFIG

	printf "   Making modules (defconfig): "
	make $MAKEOPT modules > $MODULES_DEFCONFIG 2>&1
	print_counts $MODULES_DEFCONFIG
	cp -f .config defconfig-config
fi

if [ $HAS_ALLYESCONFIG == 1 ]; then
	printf "   Making $BZIMAGE (allyesconfig): "
	make mrproper > /dev/null 2>&1
	make $MAKECONFIGOPT allyesconfig > $KERNEL_ALLYES_OUTPUT 2>&1
        no_modversions
	alt_configs
	if [ "$BASE_VERSION" == 2.4 ]; then 
		make $MAKEDEPOPT dep >> $KERNEL_ALLYES_OUTPUT 2>&1
	fi
	make $MAKEOPT $BZIMAGE >> $KERNEL_ALLYES_OUTPUT 2>&1
	print_counts $KERNEL_ALLYES_OUTPUT

	printf "   Making modules (allyesconfig): "
	make $MAKEOPT modules > $MODULES_ALLYES_OUTPUT 2>&1
	print_counts $MODULES_ALLYES_OUTPUT
	cp -f .config allyes-config
fi

if [ $HAS_ALLMODCONFIG == 1 ]; then
	printf "   Making $BZIMAGE (allmodconfig): "
	make mrproper > /dev/null 2>&1
	make $MAKECONFIGOPT allmodconfig > $KERNEL_ALLMOD_OUTPUT 2>&1
        no_modversions
	alt_configs
	if [ "$BASE_VERSION" == 2.4 ]; then 
		make $MAKEDEPOPT dep >> $KERNEL_ALLMOD_OUTPUT 2>&1
	fi
	make $MAKEOPT $BZIMAGE >> $KERNEL_ALLMOD_OUTPUT 2>&1
	print_counts $KERNEL_ALLMOD_OUTPUT

	printf "   Making modules (allmodconfig): "
	make $MAKEOPT modules > $MODULES_ALLMOD_OUTPUT 2>&1
	print_counts $MODULES_ALLMOD_OUTPUT
	cp -f .config allmodules-config
fi

print_alt_configs

#
# Build directories one at a time
#
printf "\nBuilding directories:"
make clean > /dev/null 2>&1
if [ "$BASE_VERSION" == 2.4 ]; then 
	# If 2.4 based, there may not be a .config at all.  Use either
	# the original .config or make one from the defaults.
	setup_oldconfig
fi
for i in $DIRECTORIES_LIST; do
	if [ -d $i ]; then 
		DIR_NAME=${i##*/}
		printf "\n   Building $i: " 
		make $MAKEOPT modules SUBDIRS=$i > $DIRECTORY_BUILDS.$DIR_NAME.txt 2>&1
		WARN_COUNT=`egrep " warning: " $DIRECTORY_BUILDS.$DIR_NAME.txt | sort -u | wc -l`
		ERROR_COUNT=`egrep "Error " $DIRECTORY_BUILDS.$DIR_NAME.txt | sort -u | wc -l`
		if [ $ERROR_COUNT == "0" ]; then
			if [ $WARN_COUNT == "0" ]; then
				printf "clean"
				rm $DIRECTORY_BUILDS.$DIR_NAME.txt
			else
				printf "%s warnings, %s errors" $WARN_COUNT $ERROR_COUNT
				printf "\n   %s: %s warnings, %s errors" $i $WARN_COUNT $ERROR_COUNT >> $WARN_SUMMARY
			fi
		else
			printf "%s warnings, %s errors" $WARN_COUNT $ERROR_COUNT
			printf "\n   %s: %s warnings, %s errors" $i $WARN_COUNT $ERROR_COUNT >> $FAIL_SUMMARY
			egrep " Error " $DIRECTORY_BUILDS.$DIR_NAME.txt >> $ERROR_LIST
			egrep " warning: " $DIRECTORY_BUILDS.$DIR_NAME.txt >> $WARN_LIST
		fi
	fi
done

if [ $HAS_OLDCONFIG == 1 ]; then
	printf "\n\nKernel build of original configuration: \n"
	printf "   Making $BZIMAGE (oldconfig): "
	setup_oldconfig
	make $MAKEOPT $BZIMAGE >> $KERNEL_OLDCONFIG 2>&1
	print_counts $KERNEL_OLDCONFIG

	printf "   Making modules (oldconfig): "
	make $MAKEOPT modules > $MODULES_OLDCONFIG 2>&1
        print_counts $MODULES_OLDCONFIG
fi
echo

#
# Print Summary Information
#
printf "\n\nError Summary:\n"
TMPFILE=`mktemp $VERSION.XXXXXX`
sort -u < $FAIL_SUMMARY | tee $TMPFILE
cp $TMPFILE $FAIL_SUMMARY
printf "\n\nWarning Summary:\n"
sort -u < $WARN_SUMMARY | tee $TMPFILE
cp $TMPFILE $WARN_SUMMARY

#
# Print Detailed Information
#
printf "\n\nError List:\n\n"
sort -u < $ERROR_LIST | tee $TMPFILE
cp $TMPFILE $ERROR_LIST
printf "\n\nWarning List:\n\n"
sort -u < $WARN_LIST | tee $TMPFILE
mv $TMPFILE $WARN_LIST
echo

#
# Send the PASS/FAIL status back to the PLM
#
[ $MODE == PLM ] || exit 0

ERROR_COUNT=`grep -c " Error " $ERROR_LIST`
WARN_COUNT=`grep -c " warning: " $WARN_LIST`

if [ $ERROR_COUNT == 0 ]; then
  log RESULT: PASS
else
  log RESULT: FAIL
fi

log RESULT-DETAIL: $WARN_COUNT warnings, $ERROR_COUNT errors 
leavecleanly
