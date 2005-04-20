#!/bin/sh

clear
cd ..

VER=`cat plm.spec | grep "define version" | cut -d\  -f3`
TMP=/tmp/plm-build-$$/
BASE=`pwd`
TAG="devel"

rm -f /usr/src/rpm/SOURCES/plm-$VER.tar.bz2
if [ -f "/usr/src/redhat/SOURCES/plm-$VER.tar.bz2" ]; then
  echo "ERROR: /usr/src/redhat/SOURCES/plm-$VER.tar.bz2 exists already"
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
rm -f /usr/src/redhat/SOURCES/plm-$VER.tar.bz2
rm -f /usr/src/rpm/SPECS/plm.spec
rm -f $BASE/Makefile.old

echo "Setting up build space"
cp $BASE/plm.spec /usr/src/rpm/SPECS/plm.spec
bk export -r$TAG $BASE plm-$VER
#cp -a $BASE plm-$VER 
#rm -rf `find -name CVS -type d`

echo "Compressing sources to: [/usr/src/redhat/SOURCES/plm-$VER.tar.bz2]"
tar -jcf /usr/src/redhat/SOURCES/plm-$VER.tar.bz2 plm-$VER 

echo "Running rpm"
cd /usr/src/rpm
#lsb-rpm -ba SPECS/lsb-rpm.spec 
rpmbuild -ba SPECS/plm.spec 

echo "Cleaning up the package build temp dir"
rm -rf $TMP
rm -f /var/tmp/rpm-tmp* 
