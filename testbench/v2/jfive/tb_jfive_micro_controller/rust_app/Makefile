


all:
	cargo build --release
	riscv64-unknown-elf-objdump -D target/riscv32i-unknown-none-elf/release/rust_app > rust_app.das
	riscv64-unknown-elf-objcopy -O binary target/riscv32i-unknown-none-elf/release/rust_app rust_app.bin
	python3 bin2hex.py

