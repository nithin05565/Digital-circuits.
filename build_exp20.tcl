# ==============================================================================
# Vivado 2024.1 Auto-Build Script for Experiment 20
# CMOS Inverter Digital Modeling & Verification (Verilog HDL)
# ==============================================================================

catch {close_sim -force}
if {[llength [get_projects -quiet]] > 0} {
    close_project
}

set proj_name "CMOS_Inverter_Verification"
set proj_dir  "C:/Vivado_Projects/CMOS_Inverter_Verification"
set part_name "xc7a35tcpg236-1"

file mkdir $proj_dir
create_project $proj_name $proj_dir -part $part_name -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

set src_dir "$proj_dir/hdl_sources"
file mkdir $src_dir

# ------------------------------------------------------------------------------
# 1. Design Source: cmos_inverter.v
# ------------------------------------------------------------------------------
set f_des "$src_dir/cmos_inverter.v"
set fh [open $f_des "w"]
puts $fh {`timescale 1ns / 1ps

module cmos_inverter (
    input  wire v_in,
    output wire v_out
);
    assign v_out = ~v_in;
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# 2. Simulation Testbench: tb_cmos_inverter.v
# ------------------------------------------------------------------------------
set f_tb "$src_dir/tb_cmos_inverter.v"
set fh [open $f_tb "w"]
puts $fh {`timescale 1ns / 1ps

module tb_cmos_inverter;
    reg  tb_v_in;
    wire tb_v_out;

    cmos_inverter uut (
        .v_in(tb_v_in),
        .v_out(tb_v_out)
    );

    initial begin
        $display("Time\t Input (V_in)\t Output (V_out)");
        $display("----------------------------------------");

        tb_v_in = 1'b0;
        #10;
        $display("%0tns\t\t %b\t\t %b", $time, tb_v_in, tb_v_out);

        tb_v_in = 1'b1;
        #10;
        $display("%0tns\t\t %b\t\t %b", $time, tb_v_in, tb_v_out);

        tb_v_in = 1'b0;
        #10;
        $display("%0tns\t\t %b\t\t %b", $time, tb_v_in, tb_v_out);

        $finish;
    end
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# Add sources to project, configure top modules, and launch simulation
# ------------------------------------------------------------------------------
add_files -norecurse -fileset sources_1 [list $f_des]
add_files -norecurse -fileset sim_1     [list $f_tb]

set_property top cmos_inverter    [get_filesets sources_1]
set_property top tb_cmos_inverter [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "INFO: Project created at $proj_dir/$proj_name.xpr"
launch_simulation
