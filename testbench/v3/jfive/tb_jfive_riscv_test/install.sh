
CORE_DIR=$(pwd)/_core

git clone https://github.com/riscv-software-src/riscv-tests
cd riscv-tests
git submodule update --init --recursive

autoconf
prefix=$CORE_DIR
riscv_prefix=riscv64-unknown-elf-

#./configure --prefix=$prefix --with-xlen=64
#make
#make install
# make clean

./configure --prefix=$prefix --with-xlen=32
make isa RISCV_PREFIX=$riscv_prefix
install -d $prefix/share/riscv-tests/isa
#install -p -m 644 `find isa -maxdepth 1 -type f \( -executable -o -name '*.dump' \)` $prefix/share/riscv-tests/isa

