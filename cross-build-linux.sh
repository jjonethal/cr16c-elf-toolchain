#!/bin/bash
# Source versions chosen for maximum compatibility with CR16
BINUTILS_VER="2.38"
GCC_VER="10.5.0"
NEWLIB_VER="4.2.0.20211231"



export TARGET=cr16-elf           # Target architecture (Bare-metal CR16)


export prj_root=$(pwd)
export prj_src=$prj_root/src
export prj_build=$prj_root/build-cr16-elf-linux

export PREFIX=/opt/cr16-elf

export PATH=$PREFIX/bin:$PATH


do_download=0

do_stage1=0
do_stage2=1


if [ $do_download == 1 ]
then
    [ -d  $prj_src ] || mkdir $prj_src
    [ -d  $prj_build ] || mkdir $prj_build

    cd $prj_src || { echo "directory src not exist" ; exit 1 ;  }

    [[ -d download ]] || mkdir download
    cd download || { echo error cd download ; exit 1 ; }
    echo "Downloading Binutils..."
    [[ -f binutils-$BINUTILS_VER.tar.xz ]] || wget -c "https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VER.tar.xz"

    echo "Downloading GCC..."
    [[ -f gcc-$GCC_VER.tar.xz ]] || wget -c "https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VER/gcc-$GCC_VER.tar.xz"

    echo "Downloading Newlib..."
    [[ -f newlib-$NEWLIB_VER.tar.gz ]] || wget -c "https://sourceware.org/pub/newlib/newlib-$NEWLIB_VER.tar.gz"

    cd $prj_src
    [[ -d binutils-$BINUTILS_VER ]]  || tar -xf "download/binutils-$BINUTILS_VER.tar.xz"

    [[ -d newlib-$NEWLIB_VER ]] || tar -xf "download/newlib-$NEWLIB_VER.tar.gz"

    [[ -d gcc-$GCC_VER ]] || { 
        tar -xf "download/gcc-$GCC_VER.tar.xz"

        # Download prerequisite support libraries inside the GCC directory
        cd "gcc-$GCC_VER"
        ./contrib/download_prerequisites
        cd "$prj_build" || { echo "directory $prj_build not exist" ; exit 1 ;  }
    }

fi

####### stage 1 ###################

if [ $do_stage1 == 1 ]
then

    echo ====================================
    echo ==== configure binutils stage 1 ====
    echo ====================================
    mkdir -p $prj_build/build-binutils && cd $prj_build/build-binutils
    make distclean
    $prj_src/binutils-$BINUTILS_VER/configure \
        --target=$TARGET \
        --prefix=$PREFIX \
        --disable-nls \
        --disable-werror || { echo "error configure binutils"  ;  exit 1 ; }
     
    echo ===============================
    echo ==== make binutils stage 1 ====
    echo ===============================

    make -j$(nproc)  || { echo "error make binutils"  ;  exit 1 ; }

    echo ==================================
    echo ==== install binutils stage 1 ====
    echo ==================================

    make install || { echo "error install binutils stage 1"  ;  exit 1 ; }
    cd ..

    mkdir -p $prj_build/build-gcc-s1 && cd $prj_build/build-gcc-s1
    make distclean
    $prj_src/gcc-$GCC_VER/configure \
        --target=$TARGET \
        --prefix=$PREFIX \
        --without-headers \
        --with-newlib \
        --disable-shared \
        --disable-threads \
        --disable-libssp \
        --disable-libgomp \
        --disable-multilib \
        --enable-languages=c \
        --disable-werror \
        CXXFLAGS="-O2 -std=gnu++11" \
        CFLAGS="-O2" || { echo "error configure gcc stage 1"  ;  exit 1 ; }
    make -j$(nproc) all-gcc  || { echo "error make gcc stage 1"  ;  exit 1 ; }
    make install-gcc  || { echo "error install gcc stage 1"  ;  exit 1 ; }
    cd ..


    mkdir -p $prj_build/build-newlib && cd $prj_build/build-newlib
    $prj_src/newlib-$NEWLIB_VER/configure \
        --target=$TARGET \
        --prefix=$PREFIX \
        --disable-multilib  || { echo "error configure newlib stage 1"  ;  exit 1 ; }
    make -j$(nproc) || { echo "error build newlib stage 1"  ;  exit 1 ; }
    make install  || { echo "error install nwlib stage 1"  ;  exit 1 ; }
    cd ..

fi


####### stage 2 ###################

if [ $do_stage2 == 1 ]
    then

    echo ===============================
    echo ==== configure gcc stage 2 ====
    echo ===============================

    mkdir -p $prj_build/build-gcc-final && cd $prj_build/build-gcc-final
    make distclean
    $prj_src/gcc-$GCC_VER/configure \
        --target=$TARGET \
        --prefix=$PREFIX \
        --with-headers=$PREFIX/$TARGET/include \
        --with-newlib \
        --disable-shared \
        --disable-threads \
        --disable-libssp \
        --disable-multilib \
        --disable-libstdcxx \
        --enable-languages=c,c++ \
        --disable-werror \
        CXXFLAGS="-O2 -std=gnu++11" \
        CFLAGS="-O2"    || { echo "error configure gcc stage 2"  ;  exit 1 ; }
    make -j$(nproc) || { echo "error make gcc stage 2"  ;  exit 1 ; }
    make install || { echo "error install gcc stage 2"  ;  exit 1 ; }
    cd ..
fi

