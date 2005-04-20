#!/bin/bash
#
# Mark Wong January 12, 2005 Initial
# JL        January 15, 2005 Use same version source headers, print results to stdout. 
#                            Print Little header

echo
echo Welcome to the [ Sparse on PostgreSQL ] Filter V0.1
echo
echo This filter configures the postgresql source and then
echo runs sparse on all the *.c files, excluding the contrib.
echo

HOME=`pwd`
CONFIG_LOG=$HOME/config.log
SPARSE_LOG=$HOME/sparse.log

# Clean out results from potential previous runs (debug testing...)
rm -f result.filter $CONFIG_LOG $COMPILE_LOG $HOME/ERROR

echo > $CONFIG_LOG
echo > $SPARSE_LOG

# Create a line of the result file
log () {
  echo "$@" >> $HOME/result.filter
  echo "$@"
}

#
# TEST: Did the patch program report an error
#
if [ -f patch.error ]; then
        log RESULT: FAIL
        log RESULT-DETAIL: Patch did not apply cleanly, cannot build
        exit;
fi

cd postgresql

./configure --enable-thread-safety --enable-debug >> $CONFIG_LOG 2>&1

cd src
find . -name '*.c' | awk '{print "sparse -I../../postgresql/src/include -I../../postgresql/src/interfaces/libpq " $1}' > ${HOME}/runme.sh
bash ${HOME}/runme.sh >> $SPARSE_LOG 2>&1
rm ${HOME}/runme.sh

echo Sparse Output
echo _____________ 
cat $SPARSE_LOG
echo

WARN_COUNT=`grep -c warning: $SPARSE_LOG `
ERROR_COUNT=`grep -c error: $SPARSE_LOG `

if [ $ERROR_COUNT == 0 ]; then
        log RESULT: PASS
else
        log RESULT: FAIL
fi
log RESULT-DETAIL: $WARN_COUNT warnings, $ERROR_COUNT errors

