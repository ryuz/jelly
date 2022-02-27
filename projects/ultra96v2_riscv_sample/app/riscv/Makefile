

TARGET = riscv_sample

all:
	cargo build --release
	riscv32-unknown-elf-objdump -D target/riscv32i-unknown-none-elf/release/$(TARGET) > $(TARGET).das
	riscv32-unknown-elf-objcopy -O binary target/riscv32i-unknown-none-elf/release/$(TARGET) $(TARGET).bin
	python3 bin2hex.py

