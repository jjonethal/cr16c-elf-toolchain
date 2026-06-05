#!/bin/bash
# Source versions chosen for maximum compatibility with CR16
BINUTILS_VER="2.38"
GCC_VER="12.5.0"
NEWLIB_VER="4.2.0.20211231"



export BUILD=x86_64-pc-linux-gnu
export HOST=x86_64-w64-mingw32   # Example: Toolchain will run on Windows
export TARGET=cr16-elf           # Target architecture (Bare-metal CR16)


export prj_root=$(pwd)
export prj_src=$prj_root/src

export PREFIX_STAGE1=$prj_root/cr16-stage1
export PREFIX_FINAL=$prj_root/cr16-canadian

export PATH=$PREFIX_STAGE1/bin:$PATH



[ -d  $prj_src ] || mkdir $prj_src

cd $prj_src || { echo "directory src not exist" ; exit 1 ;  }

if [ ! -d "binutils-$BINUTILS_VER" ]; then
    echo "Downloading Binutils..."
    wget -c "https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VER.tar.xz"
    tar -xf "binutils-$BINUTILS_VER.tar.xz"
fi

if [ ! -d "gcc-$GCC_VER" ]; then
    echo "Downloading GCC..."
    wget -c "https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VER/gcc-$GCC_VER.tar.xz"
    tar -xf "gcc-$GCC_VER.tar.xz"
    
    # Download prerequisite support libraries inside the GCC directory
    cd "gcc-$GCC_VER"
    ./contrib/download_prerequisites
    cd "$prj_src"
fi

if [ ! -d "newlib-$NEWLIB_VER" ]; then
    echo "Downloading Newlib..."
    wget -c "https://sourceware.org/pub/newlib/newlib-$NEWLIB_VER.tar.gz"
    tar -xf "newlib-$NEWLIB_VER.tar.gz"
fi


echo ====================================
echo ==== configure binutils stage 1 ====
echo ====================================
mkdir -p build-binutils-s1 && cd build-binutils-s1
../binutils-$BINUTILS_VER/configure \
    --build=$BUILD \
    --host=$BUILD \
    --target=$TARGET \
    --prefix=$PREFIX_STAGE1 \
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

mkdir -p build-gcc-s1 && cd build-gcc-s1
../gcc-$GCC_VER/configure \
    --build=$BUILD \
    --host=$BUILD \
    --target=$TARGET \
    --prefix=$PREFIX_STAGE1 \
    --without-headers \
    --with-newlib \
    --disable-shared \
    --disable-threads \
    --disable-libssp \
    --disable-libgomp \
    --disable-multilib \
    --enable-languages=c  || { echo "error configure gcc stage 1"  ;  exit 1 ; }
make -j$(nproc) all-gcc  || { echo "error make gcc stage 1"  ;  exit 1 ; }
make install-gcc  || { echo "error install gcc stage 1"  ;  exit 1 ; }
cd ..

mkdir -p build-newlib && cd build-newlib
../newlib-$NEWLIB_VER/configure \
    --build=$BUILD \
    --host=$BUILD \
    --target=$TARGET \
    --prefix=$PREFIX_STAGE1 \
    --disable-multilib  || { echo "error configure newlib stage 1"  ;  exit 1 ; }
make -j$(nproc) || { echo "error build newlib stage 1"  ;  exit 1 ; }
make install  || { echo "error install nwlib stage 1"  ;  exit 1 ; }
cd ..

cd build-gcc-s1
make -j$(nproc) all-target-libgcc || { echo "error make gcc stage 1"  ;  exit 1 ; }
make install-target-libgcc || { echo "error install gcc stage 1"  ;  exit 1 ; }
cd ..




echo ====================================
echo ==== configure binutils stage 2 ====
echo ====================================


mkdir -p build-binutils-canadian && cd build-binutils-canadian
../binutils-$BINUTILS_VER/configure \
    --build=$BUILD \
    --host=$HOST \
    --target=$TARGET \
    --prefix=$PREFIX_FINAL \
    --disable-nls \
    --disable-werror || { echo "error configure binutils stage 2"  ;  exit 1 ; }
make -j$(nproc)  || { echo "error make binutils stage 2"  ;  exit 1 ; }
make install || { echo "error install binutils stage 2"  ;  exit 1 ; }
cd ..


echo ===============================
echo ==== configure gcc stage 2 ====
echo ===============================

mkdir -p build-gcc-canadian && cd build-gcc-canadian
../gcc-$GCC_VER/configure \
    --build=$BUILD \
    --host=$HOST \
    --target=$TARGET \
    --prefix=$PREFIX_FINAL \
    --with-headers=$PREFIX_STAGE1/$TARGET/include \
    --with-newlib \
    --disable-shared \
    --disable-threads \
    --disable-libssp \
    --disable-multilib \
    --enable-languages=c,c++  || { echo "error configure gcc stage 2"  ;  exit 1 ; }
make -j$(nproc) || { echo "error make gcc stage 2"  ;  exit 1 ; }
make install || { echo "error install gcc stage 2"  ;  exit 1 ; }
cd ..

