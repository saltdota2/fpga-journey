create_clock -period 10.000 -name clk_a [get_ports clk_src]
create_clock -period 20.000 -name clk_b [get_ports clk_dst]

# req: A → B
set_max_delay -datapath_only 20.000 \
    -from [get_cells {u_hs/u_req/toggle_src_reg}] \
    -to   [get_cells {u_hs/u_req/sync_dst_reg[0]}]

# ack: B → A
set_max_delay -datapath_only 10.000 \
    -from [get_cells {u_hs/u_ack/toggle_src_reg}] \
    -to   [get_cells {u_hs/u_ack/sync_dst_reg[0]}]

# данные: путь есть, но семплируются только когда стабильны
set_max_delay -datapath_only 20.000 \
    -from [get_cells {u_hs/data_q_reg[*]}] \
    -to   [get_cells {u_hs/data_o_reg[*]}]

set_false_path -from [get_ports rst_n]