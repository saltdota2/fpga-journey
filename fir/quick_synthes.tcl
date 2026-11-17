# Быстрый синтез одного модуля
# Запуск: source C:/fir_task/fir_task/quick_synthes.tcl

set REPO C:/fir_task/fir_task
set PART xc7a35ticsg324-1L
set TOP  fir_lp

# закрыть предыдущую сессию, если осталась
catch {close_project}

create_project -in_memory -part $PART
read_verilog -sv [glob $REPO/rtl/*.sv]
read_xdc     $REPO/constr/constr_for_fir_lp.xdc
synth_design -top $TOP -part $PART


 opt_design
 place_design
 phys_opt_design
 route_design

 