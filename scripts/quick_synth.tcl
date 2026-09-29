# Быстрый синтез одного модуля для изучения примитивов
# Запуск: source C:/work/fpga-journey/scripts/quick_synth.tcl

set REPO C:/work/fpga-journey
set PART xc7a35ticsg324-1L
set TOP  top_cdc_handshake

# закрыть предыдущую сессию, если осталась
catch {close_project}

create_project -in_memory -part $PART
read_verilog -sv [glob $REPO/rtl/*.sv]
read_xdc     $REPO/constr/constr_for_cdc_hs.xdc
synth_design -top $TOP -part $PART


 opt_design
 place_design
 phys_opt_design
 route_design

 