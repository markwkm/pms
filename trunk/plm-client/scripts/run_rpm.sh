#!/bin/sh

clear
cd ..

VER=`cat plm.spec | grep "define version" | cut -d\  -f3`
TMP=/tmp/plm-build-$$/
BASE=`pwd`
TAG="devel"
if [ -e /etc/SuSE-release ]; then
    SOURCES_DIR=/usr/src/packages/SOURCES/
    SPECS_DIR=/usr/src/packages/SPECS/
else
    # RH
    SOURCES_DIR=/usr/src/rpm/SOURCES/
    SPECS_DIR=/usr/src/rpm/SPECS/
fi

rm -f plm-$VER.tar.bz2
if [ -f "${SOURCES_DIR}plm-$VER.tar.bz2" ]; then
  echo "ERROR: ${SOURCES_DIR}plm-$VER.tar.bz2 exists already"
  echo "If you are sure about this rebuild, please remove it and try again."
  exit
fi

if [ -d $TMP ]; then
  echo "ERROR: Temp directory exists"
  exit
fi
mkdir $TMP
cd $TMP

if [ $BASE == `pwd` ]; then 
  echo "ERROR: Still in BASE($BASE) Directory!  Bad!"
  exit
fi

echo "Building the Patch Lifecycle Manager Version: $VER"
echo "Base source: $BASE"
echo "Using temp location: $TMP"

echo "Cleaning previous build processes"
rm -f ${SOURCES_DIR}plm-$VER.tar.bz2
rm -f ${SPECS_DIR}plm.spec
rm -f $BASE/Makefile.old

echo "Setting up build space"
cvs export -r$TAG -d plm-$VER plm
echo Temp dir at `pwd`
cp $TMP/plm-$VER/plm.spec ${SPECS_DIR}plm.spec
#cp -a $BASE plm-$VER 
#rm -rf `find -name CVS -type d`

echo "Compressing sources to: [${SOURCES_DIR}plm-$VER.tar.bz2]"
tar -jcf ${SOURCES_DIR}plm-$VER.tar.bz2 plm-$VER 

echo "Running rpm"
cd /usr/src/rpm
#lsb-rpm -ba SPECS/lsb-rpm.spec 
rpmbuild -ba ${SPECS_DIR}plm.spec 

echo "Cleaning up the package build temp dir"
rm -rf $TMP
rm -f /var/tmp/rpm-tmp* 
