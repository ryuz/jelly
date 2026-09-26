
CORE_DIR=$(pwd)/_core

rm -rf $CORE_DIR
#rm -rf riscv-tests

git clone https://github.com/riscv-software-src/riscv-tests
cd riscv-tests
git checkout bcffa2b
git submodule update --init --recursive

autoconf
prefix=$CORE_DIR
riscv_prefix=${RISCV_PREFIX:-riscv32-unknown-elf-}

./configure --prefix=$prefix --with-xlen=32
make isa RISCV_PREFIX=$riscv_prefix
install -d $prefix/share/riscv-tests/isa
install -p -m 644 `find isa -maxdepth 1 -type f \( -executable -o -name '*.dump' \)` $prefix/share/riscv-tests/isa

