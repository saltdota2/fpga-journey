# Только тайминг, без привязки к пинам.
# Для экспериментов: синтез и измерение logic levels без сборки bitstream.
create_clock -period 4.000 -name sys_clk [get_ports clk]

# set_false_path -from [all_inputs] -to [all_registers]
# set_false_path -from [all_registers] -to [all_outputs]


