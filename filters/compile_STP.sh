#!/bin/bash

echo
echo Welcome to the [ Compile-STP ] Filter V1.1 
echo
echo This filter uses default config options modified for the requirements
echo of the Scalable Test Platform. http://www.osdl.org/stp/
echo
echo "This filter tests multiple configurations (UP & SMP)"
echo

HOME=`pwd`
CONFIG_LOG=$HOME/config.log
COMPILE_LOG=$HOME/compile.log

# Clean out results from potential previous runs (debug testing...)
rm -f result.filter $CONFIG_LOG $COMPILE_LOG $HOME/ERROR

echo > $CONFIG_LOG
echo > $COMPILE_LOG

for x in 1 2 3 4 5 6 7 8 9 10; do
  echo "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" >> tmp_return
done

STR=`cat tmp_return`
rm -f tmp_return

# Create a line of the result file
log () {
  echo $@ >> $HOME/result.filter
  echo $@
}

# Dump the log output (always exits after)
dump_log () {
  echo 
  echo "=== Config Options ==="
  cat $CONFIG_LOG
  echo
  echo "=== Compile log (last 150 lines) ==="
  echo
  tail -n 150 $COMPILE_LOG 

  rm -f $CONFIG_LOG $COMPILE_LOG
  exit 0
}

# Add an entry to the current .config file
config () {
  echo $@ >> .config
}

# Configure the kernel for a build with UP 
configure_kernel_UP () {
  echo -e $STR | make oldconfig &> /dev/null 

  config CONFIG_CPU_PENTIUMIII=y
  config CONFIG_ACPI=n
  config CONFIG_EXPERIMENTAL=y
  config CONFIG_MODULE_UNLOAD=y
  config CONFIG_WDTPCI=y
  config CONFIG_M386=n
  config CONFIG_M486=n
  config CONFIG_M586=n
  config CONFIG_M586TSC=n
  config CONFIG_M586MMX=n
  config CONFIG_M686=n
  config CONFIG_MPENTIUMIII=y
  config CONFIG_MPENTIUM4=n
  config CONFIG_SMP=n
  config CONFIG_SCSI=n
  config CONFIG_SERIAL_CONSOLE=y
  config CONFIG_WATCHDOG=n
  config CONFIG_I810_TCO=n
  config CONFIG_DRM_RADEON=n
  config CONFIG_DEBUG_KERNEL=y
  config CONFIG_MAGIC_SYSRQ=y
  config CONFIG_DEBUG_BUGVERBOSE=y
  config CONFIG_INTEL_RNG=n
  config CONFIG_RTC=y
  config CONFIG_AGP=n
  config CONFIG_DRM=n
  config CONFIG_USB=n
  config CONFIG_SOUND=n
  config CONFIG_HOTPLUG=n
  config CONFIG_PM=n
  config CONFIG_PARPORT=n
  config CONFIG_PNP=n
  config CONFIG_DEVFS_FS=n
  config CONFIG_EXT3_FS=m
  config CONFIG_REISERFS_FS=m
  config CONFIG_JFS_FS=m
  config CONFIG_JFS_STATISTICS=y
  config CONFIG_XFS_FS=m
  config CONFIG_MD=n
  config CONFIG_MODULES=y
  config CONFIG_INPUT=y
  config CONFIG_INPUT_MOUSEDEV=m
  config CONFIG_SERIO=y
  config CONFIG_SERIO_I8042=y
  config CONFIG_SERIO_SERPORT=y
  config CONFIG_INPUT_KEYBOARD=y
  config CONFIG_KEYBOARD_ATKBD=y
  config CONFIG_INPUT_MOUSE=y
  config CONFIG_MOUSE_PS2=y
  config CONFIG_MOUSE_SERIAL=y
  config CONFIG_SERIAL_8250=y
  config CONFIG_SERIAL_8250_CONSOLE=y
  config CONFIG_RAW_DRIVER=m
  config CONFIG_SERIAL_CORE=y
  config CONFIG_SERIAL_CORE_CONSOLE=y
  config CONFIG_KALLSYMS=y
  config CONFIG_FRAME_POINTER=n
  config CONFIG_PCMCIA=n
  config CONFIG_PCMCIA_PROBE=n
  config CONFIG_MWAVE=n
  config CONFIG_SERIAL_NONSTANDARD=n
  config CONFIG_VIDEO_DEV=n
  config CONFIG_NET_FC=n
  config CONFIG_WAN=n
  config CONFIG_ATM=n
  config CONFIG_FDDI=n
  config CONFIG_SCSI_INIA100=n
  config CONFIG_FILTER=y
  config CONFIG_E100=y

  echo -e $STR | make oldconfig &> /dev/null
  echo -e $STR | make oldconfig &> /dev/null

  cat .config &> $CONFIG_LOG
}

# Configure the kernel for a build with SMP
configure_kernel_SMP () {
  echo -e $STR | make oldconfig &> /dev/null 

  config CONFIG_CPU_PENTIUMIII=y
  config CONFIG_ACPI=n
  config CONFIG_EXPERIMENTAL=y
  config CONFIG_WDTPCI=y
  config CONFIG_M386=n
  config CONFIG_M486=n
  config CONFIG_M586=n
  config CONFIG_M586TSC=n
  config CONFIG_M586MMX=n
  config CONFIG_M686=n
  config CONFIG_MPENTIUMIII=y
  config CONFIG_MPENTIUM4=n
  config CONFIG_MTRR=y
  config CONFIG_SCSI=y                                 # ?
  config CONFIG_SCSI_AACRAID=m
  config CONFIG_SCSI_AIC7XXX=n
  config CONFIG_SCSI_AIC7XXX_OLD=n                                 # ?
  config CONFIG_SCSI_REPORT_LUNS=n
  config CONFIG_SCSI_IPS=n
  config CONFIG_SCSI_MEGARAID=y
  config CONFIG_SCSI_QLOGIC_FC=y
  config CONFIG_SCSI_QLOGIC_FC_FIRMWARE=y
  config CONFIG_SERIAL_CONSOLE=y
  config CONFIG_WATCHDOG=y
  config CONFIG_SOFT_WATCHDOG=y
  config CONFIG_I810_TCO=m
  config CONFIG_DRM=n
  config CONFIG_DRM_RADEON=n
  config CONFIG_DEBUG_KERNEL=y
  config CONFIG_MAGIC_SYSRQ=y
  config CONFIG_DEBUG_BUGVERBOSE=y
  config CONFIG_INTEL_RNG=m
  config CONFIG_RTC=y
  config CONFIG_EXT3_FS=m
  config CONFIG_REISERFS_FS=m
  config CONFIG_JFS_FS=m
  config CONFIG_JFS_STATISTICS=y
  config CONFIG_XFS_FS=m
  config CONFIG_MD=n
  config CONFIG_MODULES=y
  config CONFIG_AGP=n
  config CONFIG_USB=n
  config CONFIG_SOUND=n
  config CONFIG_INPUT=y
  config CONFIG_INPUT_MOUSEDEV=m
  config CONFIG_SERIO=y
  config CONFIG_SERIO_I8042=y
  config CONFIG_SERIO_SERPORT=y
  config CONFIG_INPUT_KEYBOARD=y
  config CONFIG_KEYBOARD_ATKBD=y
  config CONFIG_INPUT_MOUSE=y
  config CONFIG_MOUSE_PS2=y
  config CONFIG_MOUSE_SERIAL=y
  config CONFIG_SERIAL_8250=y
  config CONFIG_SERIAL_8250_CONSOLE=y
  config CONFIG_HIGHMEM=y
  config CONFIG_HIGHMEM4G=y
  config CONFIG_RAW_DRIVER=m
  config CONFIG_SERIAL_CORE=y
  config CONFIG_SERIAL_CORE_CONSOLE=y
  config CONFIG_KALLSYMS=y
  config CONFIG_FRAME_POINTER=n
  config CONFIG_PCMCIA=n
  config CONFIG_PCMCIA_PROBE=n
  config CONFIG_MWAVE=n
  config CONFIG_SERIAL_NONSTANDARD=n
  config CONFIG_VIDEO_DEV=n
  config CONFIG_NET_FC=n
  config CONFIG_WAN=n
  config CONFIG_ATM=n
  config CONFIG_FDDI=n
  config CONFIG_SCSI_INIA100=n
  config CONFIG_FILTER=y
  config CONFIG_E100=y
  config CONFIG_ISDN=n
  config CONFIG_MODULE_UNLOAD=y
  
  echo -e $STR | make oldconfig &> /dev/null
  echo -e $STR | make oldconfig &> /dev/null

  cat .config &> $CONFIG_LOG
}

# Compile the kernel 
compile_kernel () {
  make dep bzImage modules &> $COMPILE_LOG || touch $HOME/ERROR
}

# 
# Test 0: Does the linux directory exist
#
test_0 () {
  if [ ! -d linux ]; then
    log RESULT: FAIL
    log RESULT-DETAIL: Missing linux directory
    exit 0
  fi
}

#
# Test 1: Did the patch program report an error
#
test_1 () {
  if [ -f linux/patch.error ]; then
    log RESULT: FAIL
    log RESULT-DETAIL: Patch did not apply cleanly, cannot build
    exit 0
  fi
}

#
# Test 2: Does the arch/i386/boot/bzImage file exist
#
test_2 () {
  if [ ! -f arch/i386/boot/bzImage ]; then
    log RESULT: FAIL
    log RESULT-DETAIL: Missing bzImage file after build
    dump_log
  fi
}

#
# Test 3: Does the System.map file exist?
#
test_3 () {
  if [ ! -f System.map ]; then
    log RESULT: FAIL
    log RESULT-DETAIL: Missing System.map file after build
    dump_log
  fi
}

#
# Test 4: Check for the file $HOME/ERROR indicating the build failed
#
test_4 () {
  if [ -f $HOME/ERROR ]; then
    log RESULT: FAIL
    log RESULT-DETAIL: Build did not exit with 0 status
    dump_log
  fi
}

# 
# Run the pre-tests
#
test_PRE () {
  test_0
  test_1
}

#
# Run the post-tests
#
test_POST () {
  test_2
  test_3
  test_4
}

#
# Pre-test versioning information
#
`gcc -v &> .tmp.gcc`
echo Version information for host [ `hostname` ]
echo " gcc:   " `grep version .tmp.gcc | cut -d\  -f3`
echo " ccache:" `ccache -V | grep ccache | cut -d\  -f3`
echo " patch: " `patch -v | grep patch | cut -d\  -f2`
echo
`rm -f .tmp.gcc`

echo "md5sum of available source [.patch .gz .bz2]"
[ -n "`ls plm-*.patch 2> /dev/null`" ] && md5sum plm-*.patch
[ -n "`ls *.gz 2> /dev/null`" ] && md5sum *.gz
[ -n "`ls *.bz2 2> /dev/null`" ] && md5sum *.bz2
echo

test_PRE

cp -a linux linux.BAK
cd linux
configure_kernel_SMP
compile_kernel

test_POST

cd ..
rm linux -rf
mv linux.BAK linux

test_PRE

cd linux
configure_kernel_UP
compile_kernel

test_POST

#
# All Test Cases PAssed
#

log RESULT: PASS
log RESULT-DETAIL: "Compiles OK for UP & SMP with STP specific options" 

dump_log
