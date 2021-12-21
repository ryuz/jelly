

export PRJ_NAME    = ultra96v2_hls_test_tcl
export BOARD_PART  = avnet.com:ultra96v2*
export DEVICE_PART = xczu3eg-sbva484-1-i


.PHONY : all
all: clean build_hls create build

.PHONY : create
create: $(PRJ_NAME).xpr

$(PRJ_NAME).xpr:
	vivado -m64 -mode batch -source create_project.tcl

.PHONY : build
build:
	vivado -m64 -mode batch -source implementation.tcl

.PHONY : clean
clean:
	-rm -fr .Xil
	-rm -fr $(PRJ_NAME).cache
	-rm -fr $(PRJ_NAME).hw
	-rm -fr $(PRJ_NAME).ip_user_files
	-rm -fr $(PRJ_NAME).runs
	-rm -fr $(PRJ_NAME).sim
	-rm -fr $(PRJ_NAME).srcs
	-rm -fr $(PRJ_NAME).gen
	-rm -fr $(PRJ_NAME).xpr
	-rm -f vivado*.jou
	-rm -f vivado*.log


.PHONY : build_hls
build_hls:
	make -C ../../hls

.PHONY : clean_hls
clean_hls:
	make -C ../../hls clean

.PHONY : distclean
distclean: clean_hls clean



