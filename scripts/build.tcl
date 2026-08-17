#=============================================================
# Non-project build flow
# Usage: vivado -mode batch -source scripts/build.tcl -tclargs <TOP> <synth|impl>
#=============================================================

set REPO   [file normalize [file dirname [info script]]/..]
set PART   xc7a35ticsg324-1L
set OUTDIR $REPO/build

# --- Аргументы из командной строки ---------------------------
set TOP  [lindex $argv 0]
set MODE [lindex $argv 1]
if {$TOP  eq ""} { set TOP  led_blink }
if {$MODE eq ""} { set MODE impl }

file mkdir $OUTDIR

puts "INFO: top    = $TOP"
puts "INFO: mode   = $MODE"
puts "INFO: outdir = $OUTDIR"

#-------------------------------------------------------------
# 1. Read sources
#-------------------------------------------------------------
create_project -in_memory -part $PART
read_verilog -sv $REPO/rtl/$TOP.sv
read_xdc         $REPO/constr/arty_a7_35t.xdc

#-------------------------------------------------------------
# 2. Synthesis
#-------------------------------------------------------------
synth_design -top $TOP -part $PART
write_checkpoint -force $OUTDIR/post_synth.dcp
report_utilization    -file $OUTDIR/post_synth_util.rpt
report_timing_summary -file $OUTDIR/post_synth_timing.rpt

#-------------------------------------------------------------
# 3. Implementation (только в режиме impl)
#-------------------------------------------------------------
if {$MODE eq "impl"} {

    opt_design
    place_design
    report_utilization -file $OUTDIR/post_place_util.rpt
    route_design
    write_checkpoint -force $OUTDIR/post_route.dcp

    # Отчёты после трассировки — единственные, которым можно верить
    report_timing_summary    -file $OUTDIR/post_route_timing.rpt
    report_utilization       -file $OUTDIR/post_route_util.rpt
    report_drc               -file $OUTDIR/post_route_drc.rpt
    report_clock_utilization -file $OUTDIR/post_route_clk.rpt

    write_bitstream -force $OUTDIR/$TOP.bit
}

#-------------------------------------------------------------
# 4. Summary
#-------------------------------------------------------------
set wns [get_property SLACK [get_timing_paths -delay_type max]]
set whs [get_property SLACK [get_timing_paths -delay_type min]]
puts "\n============================================"
puts " BUILD DONE  (top=$TOP mode=$MODE)"
puts " WNS (setup) = $wns ns"
puts " WHS (hold)  = $whs ns"
if {$MODE eq "impl"} { puts " Bitstream   : $OUTDIR/$TOP.bit" }
puts "============================================\n"

close_project