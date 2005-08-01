#!/bin/sh
#
# AUTHORS:
#	Original script by John Cherry <cherry@osdl.org>
#	PLM port by Nathan Dabney <smurf@osdl.org>
#       Some cleanups by Roberto Nibali <ratz@drugphish.ch>
#       gcc version checking - Michael Buesch <mbuesch@freenet.de>
#
# kernstats - Kernel build stats
#
# kernstats performs the following things during a build:
#   make mrproper (unless using supplied .config) 
#   make (oldconfig|defconfig|allnoconfig|allyesconfig|allmodconfig) 
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
#			Changed gcc version to work for cross compile.
#	1.4.0		Added allnoconfig build
#	1.4.1		Produce go/no-go for Tinderbox filter
#                       Added command line options for enabling parallel
#		        build options and MODE (DEV/PLM/etc.).
#       1.4.2		Added a short option (-s) which does NOT run
#			allnoconfig, allyesconfig, and individual module
#			builds.
#	1.4.3           Updated gcc version checking - Michael Buesch <mbuesch@freenet.de>
#	1.4.4		Fixed to ignore EXTRAVERSION in the Makefile if it
#                       is not set.
#
COMPREGRESS_VERSION="1.4.4"
#
# Set MODE=DEV for regular development use
# Set MODE=PLM for use with the PLM (Patch Lifecycle Manager at OSDL).
# Default mode is dev.  If environment variable is set, use that
# instead.
#
declare    MODE=PLM
declare    SHORT=0
declare -r CPU_MAX=`grep -c processor /proc/cpuinfo`
let "JOPT=$CPU_MAX + 1"
while getopts "a:j:m:sx" opt; do
	case $opt in
		a ) let "JOPT=$CPU_MAX + $OPTARG" ;;
		j ) JOPT=$OPTARG ;;
		m ) MODE=$OPTARG ;;
		s ) SHORT=1 ;;
		x ) set -x ;;
		\? ) echo "Bad command line option, bye."
		     echo "Usage: compregress.sh [-aX] [-jY] [-mZ]"
		     echo "   where X is added to the # of CPUS for builds"
		     echo "   where Y is parallel value for the builds"
		     echo "   where Z is the MODE (DEV or PLM)"
	esac
done
shift $(($OPTIND - 1))

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
declare    MAKEOPT="KBUILD_VERBOSE=0 -ki -j$JOPT"
declare    MAKECONFIGOPT="KBUILD_VERBOSE=0 -j$JOPT"
declare    MAKEDEPOPT=""
declare    NOARCH=""
declare    CLEANUP=""
declare    ALT_CONFIGS=0
declare    ACCUM_WARNINGS=0
declare    ACCUM_ERRORS=0

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

#if [ ! -z $COMPREGRESS_MODE ]; then
#	MODE=$COMPREGRESS_MODE
#fi

#
# This should be the only way to leave this script
#
leavecleanly() {
	rm -f ${CLEANUP}
	exit $*
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

if [ $MODE == 'PLM' ]; then
    patch_id=`tail -100 ./LOG | grep Applies |tail -1|cut -d' ' -f3`
    if [ ! -z $patch_id ]; then
       ssh plm@build "mkdir -p /home/plm/plm/results/${patch_id}/$MY_ARCH.cr"
    fi
    MY_URL="http://www.osdl.org/projects/plm/results/${patch_id}/$MY_ARCH.cr"
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
	#for x in 1 2 3 4 5 6 7 8 9 10; do
		#STR="\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n${STR}"
	#done
  
	(make mrproper > /dev/null 2>&1)
	test -f oldconfig-config && cp oldconfig-config .config

	(while :; do echo -e "\n"; done) | make $MAKECONFIGOPT oldconfig &> /dev/null
	(while :; do echo -e "\n"; done) | make $MAKECONFIGOPT oldconfig &> /dev/null
	#(echo -e $STR | make $MAKECONFIGOPT oldconfig &> /dev/null)
	if [ "$BASE_VERSION" == 2.4 ]; then 
		(make $MAKEDEPOPT dep >> $KERNEL_OLDCONFIG 2>&1)
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
		#(make $MAKECONFIGOPT oldconfig > /dev/null 2>&1)
	        (while :; do echo -e "\n"; done) | make $MAKECONFIGOPT oldconfig &> /dev/null
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
	#
	# If bzImage is too big, don't count it against the
	# error count
	#
	if [ -n "$(egrep "bzImage\] Error 1" $1)" ]; then
		let "ERROR_COUNT=$ERROR_COUNT - 1"
	fi
	egrep " Error " $1 >> $ERROR_LIST
	egrep " warning: " $1 >> $WARN_LIST
	printf "%s warnings, %s errors\n" $WARN_COUNT $ERROR_COUNT
	let "ACCUM_WARNINGS=$ACCUM_WARNINGS + $WARN_COUNT"
	let "ACCUM_ERRORS=$ACCUM_ERRORS + $ERROR_COUNT"
}

# Clean out results from potential previous runs (debug testing...)
[ $MODE == PLM ] && rm -f $HOME/result.filter $HOME/ERROR

#
# Pre-test versioning information
#
GCC_VERSION="`${CROSS_COMPILE}gcc -v 2>&1 |grep 'gcc version'|cut -d\  -f3`"
if [ -z $GCC_VERSION ]; then
	GCC_VERSION="`${CROSS_COMPILE}gcc -v 2>&1 |grep 'gcc-Version'|cut -d\  -f2`"
fi
echo Version information for host [ `hostname` ]
echo " gcc:    ${GCC_VERSION}"
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
	leavecleanly 1
fi

[ ! -f Makefile ] && [ -d linux ] && cd linux

#
# Get kernel version from the top level Makefile
#
set -- $(sed -e 's%^\(.*\) =\(.*\)$%\2%;4q' < Makefile)
if [ "$4" == "" ]; then
	VERSION="$1.$2.$3"
else
	VERSION="$1.$2.$3$4"
fi
BASE_VERSION="$1.$2"

#
# TEST: Did the patch program report an error
#
if [ -f patch.error ]; then
	log RESULT: FAIL
	log RESULT-DETAIL: Patch did not apply cleanly, cannot build
	leavecleanly 1
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
# Check for build target "allmodconfig"
#
if make -n $MAKECONFIGOPT allyesconfig > /dev/null 2>&1 ; then
	HAS_ALLYESCONFIG=1
	echo "This kernel supports 'allyesconfig' (including)"
else
	HAS_ALLYESCONFIG=0
	echo "This kernel does NOT support 'allyesconfig' (skipping)"
fi

# 
# Check for build target "allnoconfig"
#
if make -n $MAKECONFIGOPT allyesconfig > /dev/null 2>&1 ; then
	HAS_ALLNOCONFIG=1
	echo "This kernel supports 'allnoconfig' (including)"
else
	HAS_ALLNOCONFIG=0
	echo "This kernel does NOT support 'allnoconfig' (skipping)"
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
   [ $HAS_ALLNOCONFIG == 0 ] && 
   [ $HAS_ALLYESCONFIG == 0 ] && 
   [ $HAS_ALLMODCONFIG == 0 ] && 
   [ $HAS_OLDCONFIG == 0 ]; then 
	echo "no .config present and oldconfig is not supported either."
	log RESULT: FAIL
	log RESULT-DETAIL: No known config methods available
	leavecleanly 1
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
# Construct output files
#
KERNEL_DEFCONFIG="$VERSION.defconfig.$BZIMAGE.txt"
KERNEL_OLDCONFIG="$VERSION.oldconfig.$BZIMAGE.txt"
KERNEL_ALLMOD_OUTPUT="$VERSION.allmodconfig.$BZIMAGE.txt"
MODULES_ALLMOD_OUTPUT="$VERSION.allmodconfig.modules.txt"
KERNEL_ALLNO_OUTPUT="$VERSION.allnoconfig.$BZIMAGE.txt"
KERNEL_ALLYES_OUTPUT="$VERSION.allyesconfig.$BZIMAGE.txt"
MODULES_ALLYES_OUTPUT="$VERSION.allyesconfig.modules.txt"
MODULES_DEFCONFIG="$VERSION.defconfig.modules.txt"
MODULES_OLDCONFIG="$VERSION.oldconfig.modules.txt"
CONFIG__DEFCONFIG="$VERSION.defconfig.config.txt"
CONFIG__ALLMOD_OUTPUT="$VERSION.allmodconfig.config.txt"
CONFIG__ALLNO_OUTPUT="$VERSION.allnoconfig.config.txt"
CONFIG__ALLYES_OUTPUT="$VERSION.allyesconfig.config.txt"
DIRECTORY_BUILDS="$VERSION.log"
FAIL_SUMMARY="$VERSION.failure.summary"
WARN_SUMMARY="$VERSION.warning.summary"
ERROR_LIST="$VERSION.error.list"
WARN_LIST="$VERSION.warning.list"

rm -f $KERNEL_DEFCONFIG $KERNEL_OLDCONFIG $KERNEL_ALLMOD_OUTPUT $KERNEL_ALLYES_OUTPUT $KERNEL_ALLNO_OUTPUT
rm -f $MODULES_ALLMOD_OUTPUT $MODULES_DEFCONFIG $MODULES_OLDCONFIG $MODULES_ALLYES_OUTPUT
rm -f $CONFIG__DEFCONFIG $CONFIG__ALLMOD_OUTPUT $CONFIG__ALLNO_OUTPUT $CONFIG__ALLYES_OUTPUT
rm -f $DIRECTORY_BUILDS* $FAIL_SUMMARY $WARN_SUMMARY $ERROR_LIST $WARN_LIST

printf "Kernel version: %s\n" $VERSION
printf "\n" > $FAIL_SUMMARY
printf "\n" > $WARN_SUMMARY

#
# Build kernel and modules (both defconfig and allmodconfig)
#
if [ ! "$BASE_VERSION" == 2.4 ]; then
	printf "Kernel build: \n"
fi

if [ $HAS_DEFCONFIG == 1 ]; then
	printf "   Making $BZIMAGE (defconfig): "
	(make mrproper > /dev/null 2>&1)
	(make $MAKECONFIGOPT defconfig > $CONFIG__DEFCONFIG 2>&1)
#	alt_configs
	if [ "$BASE_VERSION" == 2.4 ]; then 
		make $MAKEDEPOPT dep >> $KERNEL_DEFCONFIG 2>&1
	fi
	(make $MAKEOPT $BZIMAGE >> $KERNEL_DEFCONFIG 2>&1)
	print_counts $KERNEL_DEFCONFIG

	printf "   Making modules (defconfig): "
	(make $MAKEOPT modules > $MODULES_DEFCONFIG 2>&1)
	print_counts $MODULES_DEFCONFIG
	cp -f .config defconfig-config
fi

if [ "$SHORT" == 0 ] ; then
	if [ $HAS_ALLNOCONFIG == 1 ]; then
		printf "   Making $BZIMAGE (allnoconfig): "
		(make mrproper > /dev/null 2>&1)
		(make $MAKECONFIGOPT allnoconfig > $CONFIG__ALLNO_OUTPUT 2>&1)
        	no_modversions
		alt_configs
		if [ "$BASE_VERSION" == 2.4 ]; then 
			make $MAKEDEPOPT dep >> $KERNEL_ALLNO_OUTPUT 2>&1
		fi
		(make $MAKEOPT $BZIMAGE >> $KERNEL_ALLNO_OUTPUT 2>&1)
		print_counts $KERNEL_ALLNO_OUTPUT
		cp -f .config allno-config
	fi

	if [ $HAS_ALLYESCONFIG == 1 ]; then
		printf "   Making $BZIMAGE (allyesconfig): "
		(make mrproper > /dev/null 2>&1)
		(make $MAKECONFIGOPT allyesconfig > $CONFIG__ALLYES_OUTPUT 2>&1)
        	no_modversions
		alt_configs
		if [ "$BASE_VERSION" == 2.4 ]; then 
			make $MAKEDEPOPT dep >> $KERNEL_ALLYES_OUTPUT 2>&1
		fi
		(make $MAKEOPT $BZIMAGE >> $KERNEL_ALLYES_OUTPUT 2>&1)
		print_counts $KERNEL_ALLYES_OUTPUT
	
		printf "   Making modules (allyesconfig): "
		(make $MAKEOPT modules > $MODULES_ALLYES_OUTPUT 2>&1)
		print_counts $MODULES_ALLYES_OUTPUT
		cp -f .config allyes-config
	fi
fi

if [ $HAS_ALLMODCONFIG == 1 ]; then
	printf "   Making $BZIMAGE (allmodconfig): "
	(make mrproper > /dev/null 2>&1)
	(make $MAKECONFIGOPT allmodconfig > $CONFIG__ALLMOD_OUTPUT 2>&1)
        no_modversions
	alt_configs
	if [ "$BASE_VERSION" == 2.4 ]; then 
		make $MAKEDEPOPT dep >> $KERNEL_ALLMOD_OUTPUT 2>&1
	fi
	(make $MAKEOPT $BZIMAGE >> $KERNEL_ALLMOD_OUTPUT 2>&1)
	print_counts $KERNEL_ALLMOD_OUTPUT

	printf "   Making modules (allmodconfig): "
	(make $MAKEOPT modules > $MODULES_ALLMOD_OUTPUT 2>&1)
	print_counts $MODULES_ALLMOD_OUTPUT
	cp -f .config allmodules-config
fi

print_alt_configs

#
# Build directories one at a time
#
if [ "$SHORT" == 0 ] ; then
	printf "\nBuilding directories:"
	(make clean > /dev/null 2>&1)
	if [ "$BASE_VERSION" == 2.4 ]; then 
		# If 2.4 based, there may not be a .config at all.  Use either
		# the original .config or make one from the defaults.
		setup_oldconfig
	fi
	for i in $DIRECTORIES_LIST; do
		if [ -d $i ]; then 
			DIR_NAME=${i##*/}
			printf "\n   Building $i: " 
			(make $MAKEOPT modules SUBDIRS=$i > $DIRECTORY_BUILDS.$DIR_NAME.txt 2>&1)
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
fi

if [ $HAS_OLDCONFIG == 1 ]; then
	printf "\n\nKernel build of original configuration: \n"
	printf "   Making $BZIMAGE (oldconfig): "
	setup_oldconfig
	(make $MAKEOPT $BZIMAGE >> $KERNEL_OLDCONFIG 2>&1)
	WARN_COUNT=`egrep " warning: " $KERNEL_OLDCONFIG | sort -u | wc -l`
	ERROR_COUNT=`egrep " Error " $KERNEL_OLDCONFIG | sort -u | wc -l`
	printf "%s warnings, %s errors\n" $WARN_COUNT $ERROR_COUNT
	let "ACCUM_WARNINGS=$ACCUM_WARNINGS + $WARN_COUNT"
	let "ACCUM_ERRORS=$ACCUM_ERRORS + $ERROR_COUNT"

	printf "   Making modules (oldconfig): "
	(make $MAKEOPT modules > $MODULES_OLDCONFIG 2>&1)
	WARN_COUNT=`egrep " warning: " $MODULES_OLDCONFIG | sort -u | wc -l`
	ERROR_COUNT=`egrep " Error " $MODULES_OLDCONFIG | sort -u | wc -l`
	printf "%s warnings, %s errors\n" $WARN_COUNT $ERROR_COUNT
	let "ACCUM_WARNINGS=$ACCUM_WARNINGS + $WARN_COUNT"
	let "ACCUM_ERRORS=$ACCUM_ERRORS + $ERROR_COUNT"
fi
echo

#
# Print Summary Information
#
if [ "$SHORT" == 0 ] ; then
	printf "\n\nError Summary (individual module builds):\n"
	TMPFILE=`mktemp $HOME/linux/$VERSION.XXXXXX`
	sort -u < $HOME/linux/$FAIL_SUMMARY | tee $TMPFILE
	cp $TMPFILE $HOME/linux/$FAIL_SUMMARY
	printf "\n\nWarning Summary (individual module builds):\n"
	sort -u < $HOME/linux/$WARN_SUMMARY | tee $TMPFILE
	cp $TMPFILE $HOME/linux/$WARN_SUMMARY
	UR_HERE=`pwd`
	#printf "\n\nCurrent Directory:  $UR_HERE\n"
fi

if [ $MODE == 'PLM' ] && [ ! -z $patch_id ]; then
    gzip *config*txt
    scp *config*txt.gz plm@build:/home/plm/plm/results/${patch_id}/$MY_ARCH.cr/
    scp *-config plm@build:/home/plm/plm/results/${patch_id}/$MY_ARCH.cr/
    printf "Compile Output:  </PRE><a href=$MY_URL> $MY_URL </A><PRE> \n"

fi
echo

#
# Print Detailed Information
#
if [ -f $ERROR_LIST ]; then
	printf "\n\nError List:\n\n"
	sort -u < $HOME/linux/$ERROR_LIST | tee $TMPFILE
	cp $TMPFILE $HOME/linux/$ERROR_LIST
fi
if [ -f $WARN_LIST ]; then
	printf "\n\nWarning List:\n\n"
	sort -u < $HOME/linux/$WARN_LIST | tee $TMPFILE
	cp $TMPFILE $HOME/linux/$WARN_LIST
	rm $TMPFILE
fi
echo

#
# Accumulated errors for all the automated builds - defconfig,
# allnoconfig, allyesconfig, allmodconfig - are used to determine
# PASS/FAIL status.  The individual module builds are not included.
#
if [ $ACCUM_ERRORS == 0 ]; then
	if [ "$MODE" == PLM ]; then
		log RESULT: PASS
	        log RESULT-DETAIL: $ACCUM_WARNINGS warnings, $ACCUM_ERRORS errors 
	fi
	leavecleanly 0
else
	if [ "$MODE" == PLM ]; then
		log RESULT: FAIL
	        log RESULT-DETAIL: $ACCUM_WARNINGS warnings, $ACCUM_ERRORS errors 
	fi
	leavecleanly 1
fi


