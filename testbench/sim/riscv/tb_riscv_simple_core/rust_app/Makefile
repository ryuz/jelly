


all:
	cargo build --release
	riscv32-unknown-elf-objcopy -O binary target/riscv32i-unknown-none-elf/release/test_app test_app.bin
	python3 bin2hex.py 

