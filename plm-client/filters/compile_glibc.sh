#!/bin/bash

echo
echo Welcome to the [ glibc Compile ] Filter v1.0
echo
echo This filter compiles the glibc and runs make check.
echo

HOME=`pwd`
CONFIG_LOG=$HOME/config.log
COMPILE_LOG=$HOME/compile.log
CHECK_LOG=$HOME/check.log

# Clean out results from potential previous runs (debug testing...)
rm -f result.filter $CONFIG_LOG $COMPILE_LOG $HOME/ERROR

echo > $CONFIG_LOG
echo > $COMPILE_LOG
echo > $CHECK_LOG

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
  echo "=== Compile log (last 150 lines) ==="
  echo
  tail -n 150 $COMPILE_LOG 
  echo "=== Check log ==="
  cat $CHECK_LOG

  rm -f $CONFIG_LOG $COMPILE_LOG
  exit 0
}

# Add an entry to the current .config file
config () {
  echo $@ >> .config
}

# Configure the kernel for a build with UP 
configure_glibc () {
  ./configure --disable-sanity-checks &> $CONFIG_LOG 
}

# Compile the kernel 
compile_glibc () {
  make &> $COMPILE_LOG || touch $HOME/ERROR
}

#
# Test 0: Did the patch program report an error
#
test_0 () {
  if [ -f glibc/patch.error ]; then
    log RESULT: FAIL
    log RESULT-DETAIL: Patch did not apply cleanly, cannot build
    exit 0
  fi
}

# 
# Test 1: Does the glibc directory exist
#
test_1 () {
  if [ ! -d glibc ]; then
    log RESULT: FAIL
    log "RESULT-DETAIL: Missing glibc directory (internal error?)"
    exit 0
  fi
}

#
# Test 2: Do a make check.
#
test_2 () {
  if [ -f $HOME/ERROR ]; then
    log RESULT: FAIL
    log RESULT-DETAIL: Build did not exit with 0 status
    dump_log
  fi
}

#
# Test 3:
#
test_3 () {
  make check &> $CHECK_LOG || touch $HOME/ERROR
}

#
# Test 4: Check for the file $HOME/ERROR indicating the check failed
#
test_4 () {
  if [ -f $HOME/ERROR ]; then
    log RESULT: PASS
    log RESULT-DETAIL: Build passed but check failed.
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

cd glibc
configure_glibc
compile_glibc

test_POST

#
# All Test Cases Passed
#

log RESULT: PASS
log "RESULT-DETAIL: Compiles and checks OK"

dump_log
