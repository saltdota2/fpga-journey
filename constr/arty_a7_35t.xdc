#=============================================================
# Arty A7-35T constraints
#=============================================================

#-------------------------------------------------------------
# Clock: 100 MHz oscillator on E3
#-------------------------------------------------------------
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk]

#-------------------------------------------------------------
# Reset: button BTN0 (D9), active low in our design
#-------------------------------------------------------------
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports rst_n]

#-------------------------------------------------------------
# Output: LED0 (H5)
#-------------------------------------------------------------
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports led]

#-------------------------------------------------------------
# Async inputs: no timing relationship with sys_clk
#-------------------------------------------------------------
set_false_path -from [get_ports rst_n]
set_false_path -to   [get_ports led]