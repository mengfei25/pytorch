#!/bin/bash
set -xe


# Build llvm for xpu framework
LLVM_VERSION="llvmorg-16.0.6"

git clone --single-branch --depth=1 -b $LLVM_VERSION https://github.com/llvm/llvm-project
cd llvm-project
mkdir build; cd build
cmake ../llvm -DCMAKE_INSTALL_PREFIX=/opt/llvm \
    -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD=X86 \
    -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF -DCMAKE_CXX_FLAGS="-D_GLIBCXX_USE_CXX11_ABI=1"
make -j $(nproc); make install

# Link the llvm  to the /usr/bin folder.
sudo ln -s /opt/llvm/bin/llvm-config /usr/bin/llvm-config-13

cd ../..
rm -rf llvm-project

