
CORE_DIR=$(pwd)/_core

rm -rf $CORE_DIR

cd riscv-tests
make clean

#autoconf
prefix=$CORE_DIR
riscv_prefix=${RISCV_PREFIX:-riscv32-unknown-elf-}

./configure --prefix=$prefix --with-xlen=32
make isa RISCV_PREFIX=$riscv_prefix
#install -d $prefix/share/riscv-tests/isa
#install -p -m 644 `find isa -maxdepth 1 -type f \( -executable -o -name '*.dump' \)` $prefix/share/riscv-tests/isa

