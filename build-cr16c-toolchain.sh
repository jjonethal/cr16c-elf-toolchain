#!/usr/bin/env bash
# ==============================================================================
# Script: build_cr16_canadian.sh
# Purpose: Build a CR16-ELF toolchain for Windows (Host) using Linux (Build)
# ==============================================================================
set -e

# --- 1. Configurations ---
export TARGET=cr16-elf
export HOST=x86_64-w64-mingw32
export BUILD=x86_64-linux-gnu

# patch cc0
# https://gcc.gnu.org/pipermail/gcc-patches/2021-May/569657.html

# Source versions chosen for maximum compatibility with CR16
BINUTILS_VER="2.38"
GCC_VER="12.5.0"
NEWLIB_VER="4.2.0.20211231"

# Directories
WORKSPACE="$(pwd)/cr16_workspace"
PREFIX="$WORKSPACE/install_win64"
SRC_DIR="$WORKSPACE/src"
BUILD_DIR="$WORKSPACE/build"

# Force host compiler flags to handle old codebase nuances
export CFLAGS_FOR_HOST="-O2 -fpermissive -Wno-error"
export CXXFLAGS_FOR_HOST="-O2 -fpermissive -Wno-error"

echo "=== Creating directories ==="
mkdir -p "$SRC_DIR" "$BUILD_DIR" "$PREFIX"

# --- 2. Download Source Code ---
cd "$SRC_DIR"

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

# --- 3. Step 1: Build Binutils (Host = Windows) ---
echo "=== Building Cross-Binutils for Windows ==="
mkdir -p "$BUILD_DIR/binutils" && cd "$BUILD_DIR/binutils"

../../src/binutils-$BINUTILS_VER/configure \
    --build=$BUILD \
    --host=$HOST \
    --target=$TARGET \
    --prefix="$PREFIX" \
    --disable-nls \
    --disable-werror

make -j$(nproc)
make install

# --- 4. Step 2: Build Header/Prerequisite Newlib Headers ---
# A Canadian cross compiler needs target headers present during its build loop.
echo "=== Configuring Newlib Target Headers ==="
mkdir -p "$BUILD_DIR/newlib-headers" && cd "$BUILD_DIR/newlib-headers"

# We must use a temporary native cross-build layout to evaluate target code limits
../../src/newlib-$NEWLIB_VER/configure \
    --build=$BUILD \
    --host=$BUILD \
    --target=$TARGET \
    --prefix="$PREFIX/$TARGET" \
    --disable-newlib-supplied-syscalls

make install

# --- 5. Step 3: Build Core GCC (Host = Windows) ---
echo "=== Building Canadian Cross GCC ==="
mkdir -p "$BUILD_DIR/gcc" && cd "$BUILD_DIR/gcc"

# Link target headers safely into place
mkdir -p "$PREFIX/$TARGET/sys-include"
cp -r "$PREFIX/$TARGET/include/"* "$PREFIX/$TARGET/sys-include/" || true

../../src/gcc-$GCC_VER/configure \
    --build=$BUILD \
    --host=$HOST \
    --target=$TARGET \
    --prefix="$PREFIX" \
    --enable-languages=c,c++ \
    --with-sysroot="$PREFIX/$TARGET" \
    --disable-nls \
    --disable-shared \
    --disable-threads \
    --disable-libssp \
    --disable-libgomp \
    --disable-libquadmath \
    --with-newlib

# For Canadian cross, "make" is utilized rather than "make bootstrap"
make -j$(nproc)
make install

echo "==============================================================="
echo " SUCCESS: Your Windows CR16 Cross Toolchain has been created!"
echo " Binaries can be found in: $PREFIX"
echo " Copy the contents of 'install_win64' over to Windows."
echo "==============================================================="
