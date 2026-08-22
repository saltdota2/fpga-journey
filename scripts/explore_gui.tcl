#=============================================================
# Быстрый синтез одного модуля: примитивы + тайминг
# vivado -mode batch -source scripts/explore_gui.tcl -tclargs <module>
#=============================================================

set REPO [file normalize [file dirname [info script]]/..]
set PART xc7a35ticsg324-1L
set TOP  util_synth;



catch {close_project}
create_project -in_memory -part $PART
read_verilog -sv $REPO/rtl/$TOP.sv
read_xdc     $REPO/constr/timing_only.xdc
synth_design -top $TOP -part $PART

puts "\n========== PRIMITIVES =========="
foreach t {FDRE FDCE FDSE LDCE LUT1 LUT2 LUT3 LUT4 LUT5 LUT6 \
           CARRY4 MUXF7 MUXF8 DSP48E1 RAMB18E1 RAMB36E1} {
    set n [llength [get_cells -hier -filter "REF_NAME == $t"]]
    if {$n > 0} { puts [format "  %-10s %d" $t $n] }
}

puts "\n========== WORST PATH =========="
set p [lindex [get_timing_paths -delay_type max -max_paths 1] 0]
if {$p ne ""} {
    puts "  Slack        : [get_property SLACK $p] ns"
    puts "  Datapath     : [get_property DATAPATH_DELAY $p] ns"
    catch { puts "  Logic levels : [get_property LOGIC_LEVELS $p]" }
}
puts ""

puts "\n========== REGISTERS =========="
foreach c [lsort [get_cells -hier -filter "REF_NAME =~ FD*"]] {
    puts "  $c"
}
puts ""

