#! /bin/sh

# Takes care of cross-building the different UQM depencencies.
#
# This script is merely a wrapper, it specifies envvars for the scripts that do
# the actual work, then launches them. Only this script should be called directly.

# envvar HOST_TRIPLET
#
# This is used as the host triplet for the cross toolchain.
# Autoconf-using packages will get this in their --host option,
# and packages will be installed to /usr/$HOST_TRIPLET.
# Do not change unless you have changed the cross toolchain to be used
# in base-cross-toolchain.list.
export HOST_TRIPLET="i686-w64-mingw32"

# envvar SRC_ROOT_DIR
#
# This is the top-level directory where tarballs will be downloaded, unpacked,
# and built.
export SRC_ROOT_DIR="/usr/src/crossbuilt/"

echo "Crossbuilding build depenencies"
echo ""

echo "Resolving dependencies..."
echo ""
/usr/lib/crossbuild/depengine.py libsdl libsdl-image libogg libvorbis zlib > /tmp/script_list

if [ ! -f /tmp/script_list ]; then
	echo "/tmp/script_list not found - dependency resolution failed"
	exit 1
fi

# We now iterate over the lines in the output file from our dependency resolver, sourcing each
# script listed in order.
export LINES=$(cat /tmp/script_list | wc -l)
for LINE_NUMBER in $(seq ${LINES})
do
	. $(head /tmp/script_list -n{$LINE_NUMBER} | tail -n1)
done

echo ""
echo "Finished building UQM dependencies"

echo ""
echo "Perpetrating acts of horrific kludgery against the toolchain"

. /usr/lib/crossbuild/toolchain-ugly-hacks
