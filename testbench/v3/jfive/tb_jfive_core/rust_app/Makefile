


all:
	cargo build --release
	riscv64-unknown-elf-objdump -D target/riscv32i-unknown-none-elf/release/rust_app > rust_app.das
	riscv64-unknown-elf-objcopy -O binary target/riscv32i-unknown-none-elf/release/rust_app rust_app.bin
	./bin2hex.py rust_app.bin ../mem.hex 0x4000

clean:
	cargo clean

