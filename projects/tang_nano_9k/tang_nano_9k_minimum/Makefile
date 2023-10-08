

TARGET = impl/pnr/tang_nano_9k_blinking_led.fs


all: $(TARGET)

$(TARGET): tang_nano_9k_blinking_led.v tang_nano_9k_blinking_led.cst
	gw_sh tang_nano_9k_blinking_led.tcl

clean:
	rm -fr impl

run:
	openFPGALoader $(TARGET)

run2:
	programmer_cli.exe --device GW1NR-9C --run 2 --fsFile $(TARGET) --location 641


