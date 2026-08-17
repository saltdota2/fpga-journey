# Быстрый синтез одного модуля для изучения примитивов
# Запуск: source C:/work/fpga-journey/scripts/quick_synth.tcl

set REPO C:/work/fpga-journey
set PART xc7a35ticsg324-1L
set TOP  smoke_async_rst

# закрыть предыдущую сессию, если осталась
catch {close_project}

create_project -in_memory -part $PART
read_verilog -sv $REPO/rtl/$TOP.sv
synth_design -top $TOP -part $PART

puts "\n=========== UTILIZATION ==========="
report_utilization
puts "=========== END ==========="