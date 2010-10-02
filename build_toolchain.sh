#!/bin/sh
# Assumptions: your user id is added to sudoers list as ALL for ex:
#      myuserid  ALL=(ALL)       NOPASSWD: ALL
#
# All dev supporting tools are installed, flex, bison, automake, autoconf, make, gnu toolchains
# 
# Source code with all relevant dirs un-tarred/un-gzipped
#
# This script runs inside that root directory where the source code/relevant dirs are located
# minimal error checking so far
#
# Issue: Post compile of gcc fails...
#
# To do:
#     If one step fails then abort immediately instead of carrying on forward to the next step <- DONE!
#     When post compile of gcc pass - continue building the other libs with the newly built gcc
#     Make it more cleaner
#
# How to run it:
#     chmod u+x build_toolchain.sh
#     ./build_toolchain.sh > build_toolchain.log 2>&1
# Verify:
#     grep ^\>\> build_toolchain.log
#     All completion messages indicating success failure will be shown...
#
export BTURL='https://support.codesourcery.com/GNUToolchain/'
export PKGCONF='Samsung Sourcery G++ 4.4-157'
export HOST=i686-pc-linux-gnu
export BUILD=$HOST
export TARGET=arm-samsung-nucleuseabi
export PREFIX=/opt/samwave/arm
export INSTALLPREFIX=$PREFIX/install
export SYSROOT=$PREFIX/sysroot
export BUILDSYSROOT=$SYSROOT/build
export HOSTPREFIX=$PREFIX/host
#
MAKE_PARAMS=-j4
PWDDIR=$PWD
CODESOURCERY_BUILD=build_toolchain.log
#
TEMP_BINUTILS_DIR=temp-binutils-build
TEMP_NEWLIB_DIR=temp-newlib-build
TEMP_GCC_DIR_PRE=temp-gcc-build-pre
TEMP_GCC_DIR_POST=temp-gcc-build-post
#
ZLIB_DIR=zlib-1.2.3
GMP_DIR=gmp-stable
MPFR_DIR=mpfr-stable
PPL_DIR=ppl-0.10.2
CLOOG_DIR=cloog-0.15
BINUTILS_DIR=binutils-stable
GCC_DIR=gcc-4.4
NEWLIB_DIR=newlib-stable
#
# This was borrowed from http://stackoverflow.com/questions/1245295/building-arm-gnu-cross-compiler
# Written by Martin Decky
check_error(){
	if [ "$1" -ne "0" ]; then
        echo
        echo "Script failed: $2"
        exit
    fi
}
#
usage(){
	cat << EOF
usage: $0 options

This script builds the bada SDK 1.0.0 toolchain

OPTIONS:
	-h	Show this message
	-c	Perform cleanup of all builds
	-a	Build ALL 
	-p	Build preliminary libs (zlib, gmp, mpfr, ppl, cloog)
	-b	Build binutils
	-f	Build gcc (PRE) - bootstrap compiler
	-n	Build newlib
	-l	Build gcc (POST) - native compiler

Note(s):
	When -a is used, it builds preliminary, binutils, gcc (PRE), newlib and gcc (POST) in that order

BUGS:
Contact:
	rzr, x29a or t0mm13b via #bada @ irc.freenode.net or at
	http://github.com/t0mm13b/linux-samsung-gcc and leave a message for the maintainers
EOF
}

build_zlib(){
	cd $ZLIB_DIR
	sh configure --prefix=$HOSTPREFIX
	if [ $? -eq 0 ]; then
		echo ">> $ZLIB_DIR configure successful <<"
		echo ">> Doing make on $ZLIB_DIR <<"
		make $MAKE_PARAMS
		if [ $? -eq 0 ]; then
			echo ">> $ZLIB_DIR make successful <<"
			sudo make install
			if [ $? -eq 0 ]; then
				echo ">> $ZLIB_DIR make install successful <<"
				return 0
			else
				echo ">> $ZLIB_DIR make install Failed <<"
			fi
		else
			echo ">> $ZLIB_DIR make Failed <<"
		fi
	else
		echo ">> $ZLIB_DIR configure Failed <<"	
	fi
	return -1
}

build_gmp(){
	cd $GMP_DIR
	sh configure --build=$BUILD --target=$HOST --prefix=$HOSTPREFIX --disable-shared  --host=$HOST --enable-cxx  --disable-nls
	if [ $? -eq 0 ]; then
		echo ">> $GMP_DIR configure successful <<"
		echo ">> Doing make on $GMP_DIR <<"
		make $MAKE_PARAMS
		if [ $? -eq 0 ]; then
			echo ">> $GMP_DIR make successful <<"
			sudo make install
			if [ $? -eq 0 ]; then
				echo ">> $GMP_DIR make install successful <<"
				sudo make check
				if [ $? -eq 0 ]; then
					echo ">> $GMP_DIR make check successful <<"
					return 0
				else
					echo ">> $GMP_DIR make check Failed <<"
				fi
			else
				echo ">> $GMP_DIR make install Failed <<"
			fi
		else
			echo ">> $GMP_DIR make Failed <<"
		fi
	else
		echo ">> $GMP_DIR configure Failed <<"
	fi
	return -1
}

build_mpfr(){
	cd $MPFR_DIR
	sh configure --build=$BUILD --target=$TARGET --prefix=$HOSTPREFIX --disable-shared --host=$HOST --disable-nls --with-gmp=$HOSTPREFIX	
	if [ $? -eq 0 ]; then
		echo ">> $MPFR_DIR configure successful <<"
		echo ">> Doing make on $MPFR_DIR <<"
		make $MAKE_PARAMS
		if [ $? -eq 0 ]; then
			echo ">> $MPFR_DIR make successful <<"
			sudo make install
			if [ $? -eq 0 ]; then
				echo ">> $MPFR_DIR make install successful <<"
				sudo make check
				if [ $? -eq 0 ]; then
					echo ">> $MPFR_DIR make check successful <<" 
					return 0
				else
					echo ">> $MPFR_DIR make check Failed <<"
				fi
			else
				echo ">> $MPFR_DIR make install Failed <<"
			fi
		else
			echo ">> $MPFR_DIR make Failed <<"
		fi
	else
		echo ">> $MPFR_DIR configure Failed <<"
	fi
	return -1
}

build_ppl(){
	cd $PPL_DIR
	sh configure --build=$BUILD --target=$TARGET --prefix=$HOSTPREFIX --disable-shared --host=$HOST --disable-nls --with-libgmp-prefix=$HOSTPREFIX
	if [ $? -eq 0 ]; then
		echo ">> $PPL_DIR configure successful <<"
		echo ">> Doing make on $PPL_DIR <<"
		make $MAKE_PARAMS
		if [ $? -eq 0 ]; then
			echo ">> $PPL_DIR make successful <<"
			sudo make install
			if [ $? -eq 0 ]; then
				echo ">> $PPL_DIR make install successful <<"
				return 0
			else 
				echo ">> $PPL_DIR make install Failed <<"
			fi
		else
			echo ">> $PPL_DIR make Failed <<"
		fi
	else
		echo ">> $PPL_DIR configure Failed <<"
	fi
	return -1
}

build_cloog(){
	cd $CLOOG_DIR
	sh configure --build=$BUILD --target=$TARGET --prefix=$HOSTPREFIX --disable-shared --host=$HOST --disable-nls --with-ppl=$HOSTPREFIX --with-gmp=$HOSTPREFIX
	if [ $? -eq 0 ]; then
		echo ">> $CLOOG_DIR configure successful <<"
		echo ">> Doing make on $CLOOG_DIR <<"
		make $MAKE_PARAMS
		if [ $? -eq 0 ]; then
			echo ">> $CLOOG_DIR make successful <<"
			sudo make install
			if [ $? -eq 0 ]; then
				echo ">> $CLOOG_DIR make install successful <<"
				sudo make check
				if [ $? -eq 0 ]; then
					echo ">> $CLOOG_DIR make check successful <<"
					return 0
				else
					echo ">> $CLOOG_DIR make check Failed <<"
				fi
			else
				echo ">> $CLOOG_DIR make install Failed <<"
			fi
		else
			echo ">> $CLOOG_DIR make Failed <<"
		fi
	else 
		echo ">> $CLOOG_DIR configure Failed <<"
	fi
	return -1
}

build_preliminary(){
	pushd $PWDDIR
	build_zlib
	check_error $? ">> Preliminary Build: zlib failed <<"
	popd $PWDDIR
#
	pushd $PWDDIR
	build_gmp
	check_error $? ">> Preliminary Build: gmp failed <<"
	popd $PWDDIR
#
	pushd $PWDDIR
	build_mpfr
	check_error $? ">> Preliminary Build: mpfr failed <<"
	popd $PWDDIR
#
	pushd $PWDDIR
	build_ppl
	check_error $? ">> Preliminary Build: ppl failed <<"
	popd $PWDDIR
#
	pushd $PWDDIR
	build_cloog
	check_error $? ">> Preliminary Build: cloog failed <<"
	popd $PWDDIR
#
	return 0
}

build_binutils(){
	mkdir $TEMP_BINUTILS_DIR
	cd $TEMP_BINUTILS_DIR
	sh ../$BINUTILS_DIR/configure --build=$HOST \
				--target=$TARGET \
				--prefix=$PREFIX \
				--host=$HOST \
				'--with-pkgversion=$PKGCONF' \
				--with-bugurl=$BTURL \
				--disable-nls \
				--disable-poison-system-directories
	if [ $? -eq 0 ]; then
		echo ">> $BINUTILS_DIR configure successful <<"
		echo ">> Doing make on $BINUTILS_DIR <<"
		make $MAKE_PARAMS
		if [ $? -eq 0 ]; then
			echo ">> $BINUTILS_DIR make successful <<"
			sudo make install
			if [ $? -eq 0 ]; then
				echo ">> $BINUTILS_DIR make install successful <<"
				sudo mkdir -p $HOSTPREFIX/usr/lib && sudo mkdir -p $HOSTPREFIX/usr/include
				[ $? -eq 0 ] && echo ">> $HOSTPREFIX/usr/lib + $HOSTPREFIX/usr/include successful <<" || echo ">> $HOSTPREFIX/usr/lib + $HOSTPREFIX/usr/include Failed <<"
				sudo cp libiberty/libiberty.a $HOSTPREFIX/usr/lib
				[ $? -eq 0 ] && echo ">> $HOSTPREFIX/lib/libiberty.a copied successful <<" || echo ">> $HOSTPREFIX/lib/libiberty.a copy Failed <<"
				sudo cp bfd/.libs/libbfd.a $HOSTPREFIX/usr/lib
				[ $? -eq 0 ] && echo ">> $HOSTPREFIX/lib/libbfd.a copied successful <<" || echo ">> $HOSTPREFIX/lib/libbfd.a copy Failed <<"
				sudo cp bfd/bfd.h $HOSTPREFIX/usr/include
				[ $? -eq 0 ] && echo ">> $HOSTPREFIX/include/bfd.h copied successful <<" || echo ">> $HOSTPREFIX/include/bfd.h copy Failed <<"
				sudo cp ../$BINUTILS_DIR/bfd/elf-bfd.h $HOSTPREFIX/usr/include
				[ $? -eq 0 ] && echo ">> $HOSTPREFIX/include/elf-bfd.h copied successful <<" || echo ">> $HOSTPREFIX/include/elf-bfd.h copy Failed <<"
				sudo cp opcodes/.libs/libopcodes.a $HOSTPREFIX/usr/lib
				[ $? -eq 0 ] && echo ">> $HOST/lib/libopcodes.a copied successful <<" || echo ">> $HOST/lib/libopcodes.a copy Failed <<"
				return 0
			else
				echo ">> $BINUTILS_DIR make install Failed <<"
			fi
		else
			echo ">> $BINUTILS_DIR make Failed <<"
		fi
	else
		echo ">> $BINUTILS_DIR configure Failed <<"
	fi
	return -1
}


build_gcc_pre(){
	mkdir $TEMP_GCC_DIR_PRE
	cd $TEMP_GCC_DIR_PRE
	export AR_FOR_TARGET=$TARGET-ar
	export NM_FOR_TARGET=$TARGET-nm
	export OBJDUMP_FOR_TARGET=$TARGET-objdump
	export STRIP_FOR_TARGET=$TARGET-strip
	sh ../$GCC_DIR/configure --build=$HOST \
			--host=$HOST \
			--target=$TARGET \
			--enable-threads \
			--disable-libmudflap \
			--disable-libssp \
			--disable-libstdcxx-pch \
			--enable-extra-sgxx-multilibs \
			--disable-multilib \
			--with-mode=thumb \
			--with-cpu=cortex-a8 \
			--with-float=hard \
			--with-gnu-as \
			--with-gnu-ld '--with-specs=%{O2:%{!fno-remove-local-statics: -fremove-local-statics}} %{O*:%{O|O0|O1|O2|Os:;:%{!fno-remove-local-statics: -fremove-local-statics}}}' \
			--enable-languages=c,c++ \
			--enable-shared \
			--disable-lto \
			--with-newlib \
			'--with-pkgversion=$PKGCONF' \
			--with-bugurl=$BTURL \
			--disable-nls \
			--prefix=$PREFIX \
			--disable-shared \
			--disable-threads \
			--disable-libssp \
			--disable-libgomp \
			--without-headers \
			--with-newlib \
			--disable-decimal-float \
			--disable-libffi \
			--enable-languages=c \
			--with-gmp=$HOSTPREFIX \
			--with-mpfr=$HOSTPREFIX \
			--with-ppl=$HOSTPREFIX \
			'--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm' \
			--with-cloog=$HOSTPREFIX \
			--disable-libgomp \
			--disable-poison-system-directories \
			--with-build-time-tools=$PREFIX/$TARGET/bin
	if [ $? -eq 0 ]; then
		echo ">> $GCC_DIR (PRE) configure successful <<"
		echo ">> Doing make on $GCC_DIR <<"
		make $MAKE_PARAMS #LDFLAGS_FOR_TARGET=--sysroot=$PREFIX CPPFLAGS_FOR_TARGET=--sysroot=$PREFIX build_tooldir=$PREFIX
		if [ $? -eq 0 ]; then
			echo ">> $GCC_DIR (PRE) make successful <<"
			sudo make install
			if [ $? -eq 0 ]; then
				echo ">> $GCC_DIR (PRE) make install successful <<"
				return 0
			fi
		else
			echo ">> $GCC_DIR (PRE) make Failed <<"
		fi
	else
		echo ">> $GCC_DIR (PRE) configure Failed <<"
	fi	
#
	return -1
}

build_newlib(){
	mkdir $TEMP_NEWLIB_DIR
	cd $TEMP_NEWLIB_DIR
	sh ../$NEWLIB_DIR/configure --build=$BUILD \
		--target=$TARGET \
		--prefix=$PREFIX \
		--host=$HOST \
		--enable-newlib-io-long-long \
		--disable-newlib-supplied-syscalls \
		--enable-shared \
		--disable-libgloss \
		--disable-newlib-supplied-syscalls \
		--disable-nls 
	if [ $? -eq 0 ]; then
		echo ">> $NEWLIB_DIR configure successful <<"
		make $MAKE_PARAMS 
		if [ $? -eq 0 ]; then
			echo ">> $NEWLIB_DIR make successful <<"
			sudo make install
			if [ $? -eq 0 ]; then
				echo ">> $NEWLIB_DIR make install successful <<"
				return 0
			fi
		else
			echo ">> $NEWLIB_DIR make Failed <<"
		fi
	else
		echo ">> $NEWLIB_DIR configure Failed <<"
	fi
	return -1
}

build_gcc_post(){
	mkdir $TEMP_GCC_DIR_POST
	cd $TEMP_GCC_DIR_POST
	export AR_FOR_TARGET=$TARGET-ar
	export NM_FOR_TARGET=$TARGET-nm
	export OBJDUMP_FOR_TARGET=$TARGET-objdump
	export STRIP_FOR_TARGET=$TARGET-strip
	sh ../$GCC_DIR/configure --build=$HOST \
			--host=$HOST \
			--target=$TARGET \
			--enable-threads \
			--disable-libmudflap \
			--disable-libssp \
			--disable-libstdcxx-pch \
			--enable-extra-sgxx-multilibs \
			--disable-multilib \
			--with-mode=thumb \
			--with-cpu=cortex-a8 \
			--with-float=hard \
			--with-gnu-as \
			--with-gnu-ld \
			'--with-specs=%{O2:%{!fno-remove-local-statics: -fremove-local-statics}} %{O*:%{O|O0|O1|O2|Os:;:%{!fno-remove-local-statics: -fremove-local-statics}}}' \
			--enable-languages=c,c++ \
			--enable-shared \
			--disable-lto \
			--with-newlib \
			'--with-pkgversion=$PKGCONF' \
			--with-bugurl=$BTURL \
			--disable-nls \
			--prefix=$PREFIX \
			--with-headers=yes \
			--with-gmp=$HOSTPREFIX \
			--with-mpfr=$HOSTPREFIX \
			--with-ppl=$HOSTPREFIX \
			'--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm' \
			--with-cloog=$HOSTPREFIX \
			--disable-libgomp \
			--disable-poison-system-directories \
			--with-build-time-tools=$PREFIX/$TARGET/bin
	if [ $? -eq 0 ]; then
		echo ">> $GCC_DIR (POST) configure successful <<"
		echo ">> Doing make on $GCC_DIR <<"
		make $MAKE_PARAMS #LDFLAGS_FOR_TARGET=--sysroot=$PREFIX CPPFLAGS_FOR_TARGET=--sysroot=$PREFIX build_tooldir=$PREFIX
		if [ $? -eq 0 ]; then
			echo ">> $GCC_DIR (POST) make successful <<"
			sudo make install
			if [ $? -eq 0 ]; then
				echo ">> $GCC_DIR (POST) make install successful <<"
				return 0
			else
				echo ">> $GCC_DIR (POST) make install Failed <<"
			fi
		else
			echo ">> $GCC_DIR (POST) make Failed <<"
		fi
	else
		echo ">> $GCC_DIR (POST) configure Failed <<"
	fi
	return -1
}

build_all(){
	build_preliminary
	check_error $? ">> Preliminary Build failed <<"
#	
	pushd $PWDDIR
	build_binutils
	check_error $? ">> Binutils Build failed <<"
	sudo rm -rf $PWDDIR/$TEMP_BINUTILS_DIR
	[ $? -eq 0 ] && echo ">> Removed $TEMP_BINUTILS_DIR successful <<" || echo ">> Failed to remove $TEMP_BINUTILS_DIR <<"
	popd $PWDDIR
#
	pushd $PWDDIR
	build_gcc_pre
	check_error $? ">> GCC BootStrap Build failed <<"
	sudo rm -rf $PWDDIR/$TEMP_GCC_DIR_PRE
	[ $? -eq 0 ] && echo ">> Removed $TEMP_GCC_DIR_PRE (PRE) successful <<" || echo ">> Failed to remove $TEMP_GCC_DIR_PRE (PRE) <<"
	popd $PWDDIR
#
	pushd $PWDDIR
	OLDPATH=$PATH
	export PATH=$PREFIX/bin:$OLDPATH
	export CFLAGS_FOR_TARGET='-g -O2'
	build_newlib
	check_error $? ">> NewLib build failed <<"
	popd $PWDDIR
	sudo rm -rf $PWDDIR/$TEMP_NEWLIB_DIR
	[ $? -eq 0 ] && echo ">> Removed $TEMP_NEWLIB_DIR successful <<" || echo ">> Failed to remove $TEMP_NEWLIB_DIR <<"
#
	pushd $PWDDIR
	OLDPATH=$PATH
	export PATH=$PREFIX/bin:$PREFIX:$OLDPATH
	build_gcc_post
	check_error $? ">> GCC Final Build failed <<"
	popd $PWDDIR
	sudo rm -rf $PWDDIR/$TEMP_GCC_DIR_POST
	[ $? -eq 0 ] && echo ">> Removed $TEMP_GCC_DIR_POST (POST) successful <<" || echo ">> Failed to remove $TEMP_GCC_DIR_POST (POST) <<"
	return 0
}

cleanup(){
	pushd $PWDDIR
	for i in *; do 
		if [ -d $i ]; then 
			echo ">> Cleaning $i <<"
			cd $i
			make distclean && make clean
			cd ..	
		fi
	done
	popd $PWDDIR
}

echo ">> $0 started: `date` <<"
if [ $# -eq 0 ]; then
	usage
	exit 1
fi
#
OPTIND=1
while getopts "hcapbfnl" opt; do
	case "$opt" in
		h)
			usage
			exit 1
			;;
		a) 
			build_all
			;;
		c)
			cleanup
			;;
		p)	
			build_preliminary
			check_error $? ">> Preliminary Build failed <<"
			;;
		b)
			pushd $PWDDIR
			build_binutils
			check_error $? ">> Binutils Build failed <<"
			popd $PWDDIR
			sudo rm -rf $PWDDIR/$TEMP_BINUTILS_DIR
			[ $? -eq 0 ] && echo ">> Removed $TEMP_BINUTILS_DIR successful <<" || echo ">> Failed to remove $TEMP_BINUTILS_DIR <<"
			;;
		f)
			pushd $PWDDIR
			build_gcc_pre
			check_error $? ">> GCC BootStrap Build failed <<"
			popd $PWDDIR
			sudo rm -rf $PWDDIR/$TEMP_GCC_DIR_PRE
			[ $? -eq 0 ] && echo ">> Removed $TEMP_GCC_DIR_PRE (PRE) successful <<" || echo ">> Failed to remove $TEMP_GCC_DIR_PRE (PRE) <<"
			;;
		n)
			pushd $PWDDIR
			OLDPATH=$PATH
			export PATH=$PREFIX/bin:$OLDPATH
			export CFLAGS_FOR_TARGET='-g -O2'
			build_newlib
			check_error $? ">> NewLib build failed <<"
			popd $PWDDIR
			sudo rm -rf $PWDDIR/$TEMP_NEWLIB_DIR
			[ $? -eq 0 ] && echo ">> Removed $TEMP_NEWLIB_DIR successful <<" || echo ">> Failed to remove $TEMP_NEWLIB_DIR <<"
			;;
		l)
			pushd $PWDDIR
			OLDPATH=$PATH
			export PATH=$PREFIX/bin:$PREFIX:$OLDPATH
			build_gcc_post
			check_error $? ">> GCC Final Build failed <<"
			popd $PWDDIR
			sudo rm -rf $PWDDIR/$TEMP_GCC_DIR_POST
			[ $? -eq 0 ] && echo ">> Removed $TEMP_GCC_DIR_POST (POST) successful <<" || echo ">> Failed to remove $TEMP_GCC_DIR_POST (POST) <<"
			;;
		\?)
			usage
			exit
			;;
		*) 
			usage
			exit
			;;
	esac
done
echo ">> $0 stopped: `date` <<"
