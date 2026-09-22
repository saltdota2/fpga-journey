create_clock -period 10.000 -name clk_a [get_ports clk_a]
create_clock -period 50.000 -name clk_b [get_ports clk_b]

set_max_delay -datapath_only 5.000 \
    -from [get_cells u_cdc/toggle_src_reg] \
    -to   [get_cells u_cdc/sync_dst_reg[0]]



