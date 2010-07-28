#!/bin/bash

echo
echo Welcome to the [ Sparse Default ] Filter V1.0
echo
echo This filter sparses the kernel source.  All
echo options are left as defaults.
echo

HOME=`pwd`
CONFIG_LOG=$HOME/config.log
COMPILE_LOG=$HOME/compile.log

# Clean out results from potential previous runs (debug testing...)
rm -f result.filter $CONFIG_LOG $COMPILE_LOG $HOME/ERROR

echo > $CONFIG_LOG
echo > $COMPILE_LOG

# Build the \n command string
for x in 1 2 3 4 5 6 7 8 9 10; do
  echo "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" >> tmp_return
done

STR=`cat tmp_return`
rm -f tmp_return

# Create a line of the result file
log () {
  echo "$@" >> $HOME/result.filter
  echo "$@"
}

# Dump the log output (always exits after)
dump_log () {
  echo 
  echo "=== Config Options ==="
  cat $CONFIG_LOG
  echo
  echo "=== Compile log ==="
  echo
  cat $COMPILE_LOG 

  rm -f $CONFIG_LOG $COMPILE_LOG
  exit 0
}

# Configure the kernel
configure_kernel () {
  echo -e $STR | make oldconfig &> /dev/null 
  echo -e $STR | make oldconfig &> /dev/null
  echo -e $STR | make oldconfig &> /dev/null

  cat .config &> $CONFIG_LOG
}

# Compile the kernel 
compile_kernel () {
  make C=2 all &> $COMPILE_LOG || touch $HOME/ERROR
}

#
# Test 0: Did the patch program report an error
#
test_0 () {
  if [ -f linux/patch.error ]; then
    log RESULT: FAIL
    log RESULT-DETAIL: Patch did not apply cleanly, cannot build
    exit 0
  fi
}

# 
# Test 1: Does the linux directory exist
#
test_1 () {
  if [ ! -d linux ]; then
    log RESULT: FAIL
    log "RESULT-DETAIL: Missing linux directory (internal error?)"
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
configure_kernel
compile_kernel

test_POST

#
# Test Completed
#
WARN_COUNT=`grep -c warning: $COMPILE_LOG `
ERROR_COUNT=`grep -c error: $COMPILE_LOG `

if [ $ERROR_COUNT == 0 ]; then
        log RESULT: PASS
else
        log RESULT: FAIL
fi
log RESULT-DETAIL: $WARN_COUNT warnings, $ERROR_COUNT errors


dump_log
