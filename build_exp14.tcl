# ==============================================================================
# Vivado 2024.1 Auto-Build Script for Experiment 14
# Fundamental-Mode Asynchronous Sequential Circuit (Hazard-Free)
# ==============================================================================

catch {close_sim -force}
if {[llength [get_projects -quiet]] > 0} {
    close_project
}

set proj_name "exp14_async_seq"
set proj_dir  "C:/Vivado_Projects/exp14_async_seq"
set part_name "xc7a35tcpg236-1"

file mkdir $proj_dir
create_project $proj_name $proj_dir -part $part_name -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

set src_dir "$proj_dir/hdl_sources"
file mkdir $src_dir

set f_mod "$src_dir/hazard_free_async_circuit.v"
set fh [open $f_mod "w"]
puts $fh {`timescale 1ns / 1ps

module hazard_free_async_circuit (
    input  wire x1,
    input  wire x2,
    output wire Y_state,
    output wire Z_out
);
    wire w1, w2, w3;
    wire x2_bar;
    wire Y_internal;

    // Inverter layer with explicit propagation delay
    assign #2 x2_bar = ~x2;

    // Product terms + consensus term to prevent static hazards
    assign #3 w1 = x1 & x2;
    assign #3 w2 = x2_bar & Y_internal;
    assign #3 w3 = x1 & Y_internal;

    // Feedback excitation loop
    assign #3 Y_internal = w1 | w2 | w3;

    // Outputs
    assign Y_state = Y_internal;
    assign #2 Z_out = Y_internal ^ x1;
endmodule
}
close $fh

set f_tb "$src_dir/tb_async_circuit.v"
set fh [open $f_tb "w"]
puts $fh {`timescale 1ns / 1ps

module tb_async_circuit;
    reg  x1;
    reg  x2;
    wire Y_state;
    wire Z_out;

    hazard_free_async_circuit uut (
        .x1(x1),
        .x2(x2),
        .Y_state(Y_state),
        .Z_out(Z_out)
    );

    initial begin
        // Initialize inputs cleanly before non-zero delay
        x1 = 0; x2 = 0; #60;
        x1 = 1; x2 = 0; #60;
        x1 = 1; x2 = 1; #60;
        x1 = 1; x2 = 0; #60;
        x1 = 0; x2 = 0; #60;
        $finish;
    end
endmodule
}
close $fh

add_files -norecurse -fileset sources_1 [list $f_mod]
add_files -norecurse -fileset sim_1     [list $f_tb]

set_property top hazard_free_async_circuit [get_filesets sources_1]
set_property top tb_async_circuit          [get_filesets sim_1]
set_property top_lib xil_defaultlib        [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "INFO: Project created at $proj_dir/$proj_name.xpr"
launch_simulation
