

PRJ_NAME = ultra96v2_mpu9250_tcl


.PHONY : all
all: clean create build

.PHONY : create
create: $(PRJ_NAME).xpr

$(PRJ_NAME).xpr:
	vivado -m64 -mode batch -source create_project.tcl

.PHONY : build
build:
	vivado -m64 -mode batch -source implementation.tcl

.PHONY : clean
clean:
	rm -fr .Xil
	rm -fr $(PRJ_NAME).cache
	rm -fr $(PRJ_NAME).hw
	rm -fr $(PRJ_NAME).ip_user_files
	rm -fr $(PRJ_NAME).runs
	rm -fr $(PRJ_NAME).sim
	rm -fr $(PRJ_NAME).srcs
	rm -fr $(PRJ_NAME).gen
	rm -fr $(PRJ_NAME).xpr vivado*.jou  vivado*.log vivado_pid*.str 

