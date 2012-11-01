#! /bin/sh
#
# Builds and installs libvorbis for the cross toolchain.
# Sourced from build-uqm-dependencies.chroot

echo "***********************************************************************************************"
echo "--- BEGIN: crossbuild_libvorbis ---"

cd /tmp

wget --output-document=/tmp/libvorbis.tar.gz ${LIBVORBIS_URL}

if [ -f libvorbis.tar.gz ]; then

	if [ ! -d libvorbis ]; then 
		mkdir libvorbis
	fi

	tar -zxf libvorbis.tar.gz -C libvorbis
	cd libvorbis/libvorbis*
	pwd
else
	echo "crossbuild_libvorbis failed: Could not get/extract libvorbis source"
	exit 1
fi

if [ -f configure ]; then
	./configure\
		--host=${HOST_TRIPLET}\
		--build=i686-linux-gnu\
		--prefix=/usr/${HOST_TRIPLET}
else
	echo "crossbuild_libvorbis failed: Could not find ./configure (is libvorbis source tarball sane?)"
	exit 1
fi

if [ -f Makefile ]; then
	make clean
	make
	make install
else
	echo "crossbuild_libvorbis failed: Could not find Makefile (did ./configure fail?)"
	exit 1
fi

echo "--- END: crossbuild_libvorbis ---"
echo "***********************************************************************************************"
