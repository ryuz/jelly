

rm -rf riscv-tests
git clone https://github.com/riscv-software-src/riscv-tests
cd riscv-tests
git checkout bcffa2b
git submodule update --init --recursive
cd env
patch -p1 < ../../riscv-test-env.patch
cd ..

# patch の作り方
# $ cd riscv-tests/env
# $ git diff > ../../riscv-test-env.patch

autoconf
./configure --with-xlen=32
make isa

cd ..

rm -fr hex
mkdir hex
cp riscv-tests/isa/rv32ui-p-* hex/

cd hex
find . -type f ! -name "*.*" -exec riscv64-unknown-elf-objcopy -O binary {} {}.bin \;
find . -type f -name "*.bin" -exec sh -c 'python3 ../bin2hex.py 4096 "$1" > "${1%.bin}.hex"' sh {} \;
