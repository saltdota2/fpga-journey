create_clock -period 10.000 -name aclk [get_ports aclk]
set_false_path -from [get_ports aresetn]