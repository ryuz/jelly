
TARGET = jfive_sample

all:
	cargo build --release
	riscv64-unknown-elf-objdump -D target/riscv32i-unknown-none-elf/release/$(TARGET) > $(TARGET).das
	riscv64-unknown-elf-objcopy -O binary target/riscv32i-unknown-none-elf/release/$(TARGET) $(TARGET).bin
	./bin2hex.py $(TARGET).bin jfive_mem.hex 0x4000
#	cp ../jfive_mem.hex ../syn/

clean:
	cargo clean
