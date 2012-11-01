#! /bin/sh
#
# Builds and installs libsdl_image for the cross toolchain.
# Sourced from build-uqm-dependencies.chroot

# libsdl_image is an SDL package, and thus we need some extra LDFLAGS for SDL
export SDL_LIBS="-lmingw32 -lSDLmain -lSDL"

echo "***********************************************************************************************"
echo "--- BEGIN: crossbuild_libsdl_image ---"

cd /tmp

wget --output-document=/tmp/libsdl_image.tar.gz ${LIBSDL_IMAGE_URL}

if [ -f libsdl_image.tar.gz ]; then

	if [ ! -d libsdl_image ]; then 
		mkdir libsdl_image
	fi

	tar -zxf libsdl_image.tar.gz -C libsdl_image
	cd libsdl_image/SDL_image*
else
	echo "crossbuild_libsdl_image failed: Could not get/extract libsdl_image source"
	exit 1
fi

if [ -f configure ]; then
	./configure\
		--host=${HOST_TRIPLET}\
		--build=i686-linux-gnu\
		--prefix=/usr/${HOST_TRIPLET}
else
	echo "crossbuild_libsdl_image failed: Could not find ./configure (is libsdl_image source tarball sane?)"
	exit 1
fi

if [ -f Makefile ]; then
	make clean
	make
	make install
else
	echo "crossbuild_libsdl_image failed: Could not find Makefile (did ./configure fail?)"
	exit 1
fi

echo "--- END: crossbuild_libsdl_image ---"
echo "***********************************************************************************************"
