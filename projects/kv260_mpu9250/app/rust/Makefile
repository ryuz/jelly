


.PHONY: all
all: build

.PHONY: build
build:
	make -C apu build
	make -C rpu build

.PHONY: clean
clean:
	make -C apu clean
	make -C rpu clean

.PHONY: run
run:
	make -C rpu run
	make -C apu run

.PHONY: stop
stop:
	make -C rpu stop

