# ==============================================================================
# Vivado 2024.1 Auto-Build Script for Experiment 16
# Implementation of Boolean Functions Using PLA and PAL Structures (Pre-Verification)
# F1 = A'B + AC   |   F2 = AB + A'C
# ==============================================================================

catch {close_sim -force}
if {[llength [get_projects -quiet]] > 0} {
    close_project
}

set proj_name "exp16_pla_pal"
set proj_dir  "C:/Vivado_Projects/exp16_pla_pal"
set part_name "xc7a35tcpg236-1"

file mkdir $proj_dir
create_project $proj_name $proj_dir -part $part_name -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

set src_dir "$proj_dir/hdl_sources"
file mkdir $src_dir

# ------------------------------------------------------------------------------
# 1. Design Source: pla_circuit.v (Programmable AND Plane + Programmable OR Plane)
# ------------------------------------------------------------------------------
set f_pla "$src_dir/pla_circuit.v"
set fh [open $f_pla "w"]
puts $fh {`timescale 1ns / 1ps

module pla_circuit (
    input  wire A,
    input  wire B,
    input  wire C,
    output wire P1,
    output wire P2,
    output wire P3,
    output wire P4,
    output wire F1,
    output wire F2
);
    // Programmable AND Plane (Product Terms)
    assign P1 = (~A) & B;
    assign P2 = A & C;
    assign P3 = A & B;
    assign P4 = (~A) & C;

    // Programmable OR Plane (Sum of Product Terms)
    assign F1 = P1 | P2;
    assign F2 = P3 | P4;
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# 2. Design Source: pal_circuit.v (Programmable AND Plane + Fixed OR Plane)
# ------------------------------------------------------------------------------
set f_pal "$src_dir/pal_circuit.v"
set fh [open $f_pal "w"]
puts $fh {`timescale 1ns / 1ps

module pal_circuit (
    input  wire A,
    input  wire B,
    input  wire C,
    output wire F1,
    output wire F2
);
    // Dedicated Programmable AND arrays feeding each Fixed-OR output
    wire f1_p1, f1_p2;
    wire f2_p1, f2_p2;

    assign f1_p1 = (~A) & B;
    assign f1_p2 = A & C;
    assign F1    = f1_p1 | f1_p2; // Fixed OR gate for F1

    assign f2_p1 = A & B;
    assign f2_p2 = (~A) & C;
    assign F2    = f2_p1 | f2_p2; // Fixed OR gate for F2
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# 3. Simulation Testbench: tb_pla_pal.v (Sweeps all 8 input combinations)
# ------------------------------------------------------------------------------
set f_tb "$src_dir/tb_pla_pal.v"
set fh [open $f_tb "w"]
puts $fh {`timescale 1ns / 1ps

module tb_pla_pal;
    reg  A, B, C;
    wire P1, P2, P3, P4;
    wire F1_pla, F2_pla;
    wire F1_pal, F2_pal;

    pla_circuit uut_pla (
        .A(A), .B(B), .C(C),
        .P1(P1), .P2(P2), .P3(P3), .P4(P4),
        .F1(F1_pla), .F2(F2_pla)
    );

    pal_circuit uut_pal (
        .A(A), .B(B), .C(C),
        .F1(F1_pal), .F2(F2_pal)
    );

    integer i;

    initial begin
        $display("A B C | P1 P2 P3 P4 | F1_pla F2_pla | F1_pal F2_pal");
        $display("---------------------------------------------------");
        for (i = 0; i < 8; i = i + 1) begin
            {A, B, C} = i[2:0];
            #10;
            $display("%b %b %b |  %b  %b  %b  %b |    %b      %b   |    %b      %b",
                     A, B, C, P1, P2, P3, P4, F1_pla, F2_pla, F1_pal, F2_pal);
        end
        $finish;
    end
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# Add sources to project, configure top modules, and launch simulation
# ------------------------------------------------------------------------------
add_files -norecurse -fileset sources_1 [list $f_pla $f_pal]
add_files -norecurse -fileset sim_1     [list $f_tb]

set_property top pla_circuit [get_filesets sources_1]
set_property top tb_pla_pal  [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "INFO: Project created at $proj_dir/$proj_name.xpr"
launch_simulation
