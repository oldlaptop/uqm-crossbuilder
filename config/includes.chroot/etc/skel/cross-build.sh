#! /bin/sh
#
# This is a helper script for cross-building UQM. Please copy this
# into any UQM source directory you extract and invoke it as you
# would build.sh

# envvar CROSS_ROOT
#
# The root of our cross environment. This is not used
# directly by the build system but simplifies definition
# of our other envvars.
export CROSS_ROOT=/usr/i686-w64-mingw32

# envvar BUILD_HOST
#
# Tells the UQM build system that it is crosscompiling with
# mingw32.
export BUILD_HOST=MINGW32

# envvar PKG_CONFIG_PATH
#
# Tells the UQM build system where to find the pkgconfig files
# for our cross-toolchain
export PKG_CONFIG_PATH=$CROSS_ROOT/lib/pkgconfig

# We need these extra LDFLAGS so UQM will compile properly against
# libsdl (and find libsdl-image).
export LDFLAGS="-lmingw32 -lSDLmain"

# Uncomment this line to turn on HIGHLY verbose debug information
# (you will want to redirect it to a file with something like
# ./cross-build.sh uqm 2> build.log
#export SH="sh -x"

# UQM does not use autoconf and therefore does not know about
# autoconf host triplets. To fix this we have created symlinks
# in ${CROSS_ROOT}/build to the appropriate tools and will set
# PATH here so they override any native tools present.
export PATH=$CROSS_ROOT/bin:$PATH

# Meant to keep the envvars from being tampered with by other shells
# (according to UQM documentation)
unset ENV BASH_ENV

# Enable parallel building if requested
if [ $PARALLEL ]
then
	export MAKEFLAGS=-j$(nproc)
fi

./build.sh $@
