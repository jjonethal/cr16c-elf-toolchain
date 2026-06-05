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

[ -d  $prj_root/src ] || mkdir $prj_root/src

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
    cd "$SRC_DIR"
fi

if [ ! -d "newlib-$NEWLIB_VER" ]; then
    echo "Downloading Newlib..."
    wget -c "https://sourceware.org/pub/newlib/newlib-$NEWLIB_VER.tar.gz"
    tar -xf "newlib-$NEWLIB_VER.tar.gz"
fi



mkdir -p build-binutils-s1 && cd build-binutils-s1
../binutils-$BINUTILS_VER/configure \
    --build=$BUILD \
    --host=$BUILD \
    --target=$TARGET \
    --prefix=$PREFIX_STAGE1 \
    --disable-nls \
    --disable-werror
make -j$(nproc)
make install
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
    --enable-languages=c
make -j$(nproc) all-gcc
make install-gcc
cd ..

mkdir -p build-newlib && cd build-newlib
../newlib-$NEWLIB_VER/configure \
    --build=$BUILD \
    --host=$BUILD \
    --target=$TARGET \
    --prefix=$PREFIX_STAGE1 \
    --disable-multilib
make -j$(nproc)
make install
cd ..

cd build-gcc-s1
make -j$(nproc) all-target-libgcc
make install-target-libgcc
cd ..

