# Только тайминг, без привязки к пинам.
# Для экспериментов: синтез и измерение logic levels без сборки bitstream.
create_clock -period 10.000 -name sys_clk [get_ports clk]