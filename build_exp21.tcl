# ==============================================================================
# Vivado 2024.1 Auto-Build Script for Experiment 21
# MOS C-V Operational State Emulator (Verilog HDL)
# ==============================================================================

catch {close_sim -force}
if {[llength [get_projects -quiet]] > 0} {
    close_project
}

set proj_name "MOS_Capacitor_State_Verification"
set proj_dir  "C:/Vivado_Projects/MOS_Capacitor_State_Verification"
set part_name "xc7a35tcpg236-1"

file mkdir $proj_dir
create_project $proj_name $proj_dir -part $part_name -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

set src_dir "$proj_dir/hdl_sources"
file mkdir $src_dir

# ------------------------------------------------------------------------------
# 1. Design Source: mos_cv_emulator.v
# ------------------------------------------------------------------------------
set f_des "$src_dir/mos_cv_emulator.v"
set fh [open $f_des "w"]
puts $fh {`timescale 1ns / 1ps

module mos_cv_emulator (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] v_gate_digitized,     // 8'h00 = -2.0V, 8'hFF = +2.0V
    output reg  [1:0] mos_region,           // 2'b00: Accum, 2'b01: Depl, 2'b10: Inv
    output reg        state_deviation_alert
);
    localparam [7:0] PARAM_V_FB = 8'h60;
    localparam [7:0] PARAM_V_TH = 8'hA6;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mos_region <= 2'b00;
            state_deviation_alert <= 1'b0;
        end else begin
            if (v_gate_digitized < PARAM_V_FB) begin
                mos_region <= 2'b00; // Accumulation
            end else if (v_gate_digitized >= PARAM_V_FB && v_gate_digitized < PARAM_V_TH) begin
                mos_region <= 2'b01; // Depletion
            end else begin
                mos_region <= 2'b10; // Inversion
            end

            if (v_gate_digitized > 8'hF0 || v_gate_digitized < 8'h0F) begin
                state_deviation_alert <= 1'b1;
            end else begin
                state_deviation_alert <= 1'b0;
            end
        end
    end
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# 2. Simulation Testbench: tb_mos_cv_emulator.v
# ------------------------------------------------------------------------------
set f_tb "$src_dir/tb_mos_cv_emulator.v"
set fh [open $f_tb "w"]
puts $fh {`timescale 1ns / 1ps

module tb_mos_cv_emulator;
    reg        clk;
    reg        rst_n;
    reg  [7:0] v_gate_digitized;
    wire [1:0] mos_region;
    wire       state_deviation_alert;

    mos_cv_emulator uut (
        .clk(clk),
        .rst_n(rst_n),
        .v_gate_digitized(v_gate_digitized),
        .mos_region(mos_region),
        .state_deviation_alert(state_deviation_alert)
    );

    // 100 MHz System Clock (10 ns period)
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        v_gate_digitized = 8'h00;

        #20;
        rst_n = 1;
        $display("Time\t Input Hex\t MOS Region (00:Acc, 01:Dep, 10:Inv)\t Alert");
        $display("---------------------------------------------------------------------");

        // Test Step 1: Accumulation
        v_gate_digitized = 8'h20; #20;
        $display("%0tns\t 8'h%h\t\t %b\t %b", $time, v_gate_digitized, mos_region, state_deviation_alert);

        // Test Step 2: Depletion
        v_gate_digitized = 8'h80; #20;
        $display("%0tns\t 8'h%h\t\t %b\t %b", $time, v_gate_digitized, mos_region, state_deviation_alert);

        // Test Step 3: Strong Inversion
        v_gate_digitized = 8'hC0; #20;
        $display("%0tns\t 8'h%h\t\t %b\t %b", $time, v_gate_digitized, mos_region, state_deviation_alert);

        // Test Step 4: Out-of-Bounds Alert
        v_gate_digitized = 8'hFA; #20;
        $display("%0tns\t 8'h%h\t\t %b\t %b", $time, v_gate_digitized, mos_region, state_deviation_alert);

        #20;
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

set_property top mos_cv_emulator    [get_filesets sources_1]
set_property top tb_mos_cv_emulator [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "INFO: Project created at $proj_dir/$proj_name.xpr"
launch_simulation
