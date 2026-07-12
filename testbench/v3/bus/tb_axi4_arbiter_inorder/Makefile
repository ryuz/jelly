# Test targets
.PHONY: all xsim verilator clean distclean

all:
	@echo "Available targets:"
	@echo "  make xsim      - Run test with xsim"
	@echo "  make verilator - Run test with verilator"
	@echo "  make clean     - Clean build artifacts"
	@echo "  make distclean - Clean all generated files"

xsim:
	$(MAKE) -C xsim all

verilator:
	$(MAKE) -C verilator all

clean:
	$(MAKE) -C xsim clean
	$(MAKE) -C verilator clean

distclean:
	$(MAKE) -C xsim distclean
	$(MAKE) -C verilator distclean
