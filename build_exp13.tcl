# ==============================================================================
# Vivado 2024.1 Auto-Build Script for Experiment 13
# Mealy and Moore Finite State Machines - Overlapping '101' Sequence Detector
# ==============================================================================

# Close any open simulation or project safely
catch {close_sim -force}
if {[llength [get_projects -quiet]] > 0} {
    close_project
}

# Project settings (path has no spaces for Vivado compatibility)
set proj_name "exp13_fsm"
set proj_dir  "C:/Vivado_Projects/exp13_fsm"
set part_name "xc7a35tcpg236-1"

# Create the Vivado project (.xpr)
file mkdir $proj_dir
create_project $proj_name $proj_dir -part $part_name -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# Directory for generated Verilog source files
set src_dir "$proj_dir/hdl_sources"
file mkdir $src_dir

# ------------------------------------------------------------------------------
# 1. Design Source: mealy_101_detector.v (Overlapping '101' Mealy FSM)
# ------------------------------------------------------------------------------
set f_mealy "$src_dir/mealy_101_detector.v"
set fh [open $f_mealy "w"]
puts $fh {`timescale 1ns / 1ps

module mealy_101_detector (
    input  wire clk,
    input  wire rst,
    input  wire x,
    output reg  z
);
    // State Space Definition using Binary Encoding
    parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10;
    reg [1:0] current_state, next_state;

    // Block 1: Synchronous State Register
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= S0;
        else
            current_state <= next_state;
    end

    // Block 2: Combinatorial Next-State Logic
    always @(*) begin
        case (current_state)
            S0: next_state = (x) ? S1 : S0;
            S1: next_state = (x) ? S1 : S2;
            S2: next_state = (x) ? S1 : S0; // Overlapping: loop back to S1 on 1
            default: next_state = S0;
        endcase
    end

    // Block 3: Combinatorial Mealy Output Logic (State + Input Dependent)
    always @(*) begin
        case (current_state)
            S2: z = (x) ? 1'b1 : 1'b0; // Asserts immediately when x=1 in S2
            default: z = 1'b0;
        endcase
    end
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# 2. Design Source: moore_101_detector.v (Overlapping '101' Moore FSM)
# ------------------------------------------------------------------------------
set f_moore "$src_dir/moore_101_detector.v"
set fh [open $f_moore "w"]
puts $fh {`timescale 1ns / 1ps

module moore_101_detector (
    input  wire clk,
    input  wire rst,
    input  wire x,
    output reg  z
);
    // State Encoding Definitions (Extra state S3 for clock-aligned output)
    parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11;
    reg [1:0] current_state, next_state;

    // Block 1: Synchronous State Register
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= S0;
        else
            current_state <= next_state;
    end

    // Block 2: Combinatorial Next-State Logic
    always @(*) begin
        case (current_state)
            S0: next_state = (x) ? S1 : S0;
            S1: next_state = (x) ? S1 : S2;
            S2: next_state = (x) ? S3 : S0; // On 1, advance to match state S3
            S3: next_state = (x) ? S1 : S2; // Overlapping detection handler
            default: next_state = S0;
        endcase
    end

    // Block 3: Pure Moore Output Logic (Dependent only on Current State)
    always @(*) begin
        case (current_state)
            S3: z = 1'b1; // Aligned with clock edge entry into S3
            default: z = 1'b0;
        endcase
    end
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# 3. Simulation Testbench: tb_fsm_detectors.v
# ------------------------------------------------------------------------------
set f_tb "$src_dir/tb_fsm_detectors.v"
set fh [open $f_tb "w"]
puts $fh {`timescale 1ns / 1ps

module tb_fsm_detectors;
    reg  clk;
    reg  rst;
    reg  x;
    wire z_mealy;
    wire z_moore;

    // Instantiate Mealy Sequence Detector
    mealy_101_detector uut_mealy (
        .clk(clk),
        .rst(rst),
        .x(x),
        .z(z_mealy)
    );

    // Instantiate Moore Sequence Detector
    moore_101_detector uut_moore (
        .clk(clk),
        .rst(rst),
        .x(x),
        .z(z_moore)
    );

    // 20 ns Clock Period (10 ns High, 10 ns Low)
    always #10 clk = ~clk;

    initial begin
        // Reset Phase
        clk = 0; rst = 1; x = 0;
        #15 rst = 0;

        // Input Stream: 1 -> 0 -> 1 -> 0 -> 1 (Two overlapping '101' detections)
        x = 1; #20; // Bit 1: 1 (enters S1)
        x = 0; #20; // Bit 2: 0 (enters S2)
        x = 1; #20; // Bit 3: 1 -> First '101' detected (Mealy immediately, Moore at posedge)
        x = 0; #20; // Bit 4: 0 (enters S2 again)
        x = 1; #20; // Bit 5: 1 -> Overlapping '101' detected

        // Clear input and finish
        x = 0; #40;
        $finish;
    end
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# Add sources to project, configure top modules, and launch simulation
# ------------------------------------------------------------------------------
add_files -norecurse -fileset sources_1 [list $f_mealy $f_moore]
add_files -norecurse -fileset sim_1     [list $f_tb]

set_property top mealy_101_detector [get_filesets sources_1]
set_property top tb_fsm_detectors   [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "INFO: Project created at $proj_dir/$proj_name.xpr"
launch_simulation
