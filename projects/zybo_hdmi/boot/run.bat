copy ..\syn\vivado2016.1\zybo_hdmi.runs\impl_1\top.bit .
copy ..\ip\vivado2016.1\processing_system7_0\ps7_init.tcl .

call xmd -tcl run.tcl


pause
