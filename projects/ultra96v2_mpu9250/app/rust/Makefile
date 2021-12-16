


.PHONY: all
all: build

.PHONY: build
build:
	make -C apu build
	make -C rpu build

.PHONY: run
run:
	make -C rpu run
	make -C apu run

.PHONY: stop
stop:
	make -C rpu stop

