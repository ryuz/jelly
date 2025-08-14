

TARGET = jfive_sample

.PHONY: all
all: build

.PHONY: build
build:
	cargo build --release
	riscv64-unknown-elf-objdump -D target/riscv32i-unknown-none-elf/release/$(TARGET) > $(TARGET).das
	riscv64-unknown-elf-objcopy -O binary target/riscv32i-unknown-none-elf/release/$(TARGET) $(TARGET).bin
	python3 bin2hex.py

.PHONY: clean
clean:
	cargo clean
	rm -f $(TARGET).das
	rm -f $(TARGET).bin
	rm -f mem.hex

