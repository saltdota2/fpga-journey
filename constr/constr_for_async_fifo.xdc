# Такты (периоды поменяй на свои)
create_clock -name clk_w -period 10.000  [get_ports clk_w]   ;# 100 MHz
create_clock -name clk_r -period 13.333  [get_ports clk_r]   ;# 75 MHz

set p_r   [get_property PERIOD [get_clocks clk_r]]
set p_min [expr {min([get_property PERIOD [get_clocks clk_w]], $p_r)}]

# CDC: gray-указатели
set_max_delay -datapath_only -from [get_cells -hier -filter {NAME =~ *wgray_q_reg*}] \
                             -to   [get_cells -hier -filter {NAME =~ *wgray_sync_reg*}] $p_min
set_max_delay -datapath_only -from [get_cells -hier -filter {NAME =~ *rgray_q_reg*}] \
                             -to   [get_cells -hier -filter {NAME =~ *rgray_sync_reg*}] $p_min

set_bus_skew -from [get_cells -hier -filter {NAME =~ *wgray_q_reg*}] \
             -to   [get_cells -hier -filter {NAME =~ *wgray_sync_reg*}] $p_min
set_bus_skew -from [get_cells -hier -filter {NAME =~ *rgray_q_reg*}] \
             -to   [get_cells -hier -filter {NAME =~ *rgray_sync_reg*}] $p_min

# Память (LUTRAM) -> rd_data_o
set_max_delay -datapath_only -from [get_clocks clk_w] \
                             -to   [get_cells -hier -filter {NAME =~ *rd_data_o_reg*}] $p_r
