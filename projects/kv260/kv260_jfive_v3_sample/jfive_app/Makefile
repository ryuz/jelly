


all:
	cargo build --release
	riscv64-unknown-elf-objdump -D target/riscv32i-unknown-none-elf/release/jfive_app > jfive_app.das
	riscv64-unknown-elf-objcopy -O binary target/riscv32i-unknown-none-elf/release/jfive_app jfive_app.bin
	python3 bin2hex.py

