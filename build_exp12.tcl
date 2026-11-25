# ==============================================================================
# Vivado 2024.1 Auto-Build Script for Experiment 12
# 4-Bit SISO, SIPO, PISO, and PIPO Shift Registers (Verilog HDL)
# ==============================================================================

# Close any open simulation or project safely
catch {close_sim -force}
if {[llength [get_projects -quiet]] > 0} {
    close_project
}

# Project settings (path has no spaces for Vivado compatibility)
set proj_name "exp12_shift_registers"
set proj_dir  "C:/Vivado_Projects/exp12_shift_registers"
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
# 1. Design Source: siso_sipo_registers.v (4-Bit SISO & SIPO)
# ------------------------------------------------------------------------------
set f_siso "$src_dir/siso_sipo_registers.v"
set fh [open $f_siso "w"]
puts $fh {`timescale 1ns / 1ps

module siso_sipo_registers (
    input  wire       clk,
    input  wire       rst,
    input  wire       serial_in,
    output wire       serial_out,
    output wire [3:0] parallel_out
);
    reg [3:0] shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 4'b0000;
        end else begin
            shift_reg <= {shift_reg[2:0], serial_in};
        end
    end

    assign serial_out   = shift_reg[3];
    assign parallel_out = shift_reg;
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# 2. Design Source: piso_pipo_registers.v (4-Bit PISO & PIPO)
# ------------------------------------------------------------------------------
set f_piso "$src_dir/piso_pipo_registers.v"
set fh [open $f_piso "w"]
puts $fh {`timescale 1ns / 1ps

module piso_pipo_registers (
    input  wire       clk,
    input  wire       rst,
    input  wire       load_shift,     // 1 = Parallel Load, 0 = Serial Shift
    input  wire       serial_in_piso,
    input  wire [3:0] parallel_in,
    output wire       serial_out_piso,
    output reg  [3:0] parallel_out_pipo
);
    reg [3:0] piso_reg;

    // PISO Shift Register Block
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            piso_reg <= 4'b0000;
        end else begin
            if (load_shift)
                piso_reg <= parallel_in;
            else
                piso_reg <= {piso_reg[2:0], serial_in_piso};
        end
    end

    assign serial_out_piso = piso_reg[3];

    // PIPO Register Block
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            parallel_out_pipo <= 4'b0000;
        end else begin
            parallel_out_pipo <= parallel_in;
        end
    end
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# 3. Simulation Testbench: tb_shift_registers.v
# ------------------------------------------------------------------------------
set f_tb "$src_dir/tb_shift_registers.v"
set fh [open $f_tb "w"]
puts $fh {`timescale 1ns / 1ps

module tb_shift_registers;
    reg        clk;
    reg        rst;
    reg        serial_in;
    reg        load_shift;
    reg        serial_in_piso;
    reg  [3:0] parallel_in;

    wire       serial_out;
    wire [3:0] parallel_out;
    wire       serial_out_piso;
    wire [3:0] parallel_out_pipo;

    siso_sipo_registers uut_siso_sipo (
        .clk(clk),
        .rst(rst),
        .serial_in(serial_in),
        .serial_out(serial_out),
        .parallel_out(parallel_out)
    );

    piso_pipo_registers uut_piso_pipo (
        .clk(clk),
        .rst(rst),
        .load_shift(load_shift),
        .serial_in_piso(serial_in_piso),
        .parallel_in(parallel_in),
        .serial_out_piso(serial_out_piso),
        .parallel_out_pipo(parallel_out_pipo)
    );

    // 20 ns Clock Period (10 ns High, 10 ns Low)
    always #10 clk = ~clk;

    initial begin
        // Initialize and assert Reset
        clk = 0; rst = 1;
        serial_in = 0; load_shift = 0; serial_in_piso = 0;
        parallel_in = 4'b1011;
        #15 rst = 0;

        // Cycle 1: SISO/SIPO shift in '1' | PISO parallel load 4'b1011 | PIPO latches 4'b1011
        serial_in = 1; load_shift = 1; #20;

        // Cycle 2: SISO/SIPO shift in '0' | PISO switch to serial shift
        serial_in = 0; load_shift = 0; #20;

        // Cycle 3: SISO/SIPO shift in '1' | PISO shifts next bit
        serial_in = 1; #20;

        // Cycle 4: SISO/SIPO shift in '1' (parallel_out = 1011, serial_out = 1)
        serial_in = 1; parallel_in = 4'b0101; #20;

        // Cycle 5: PIPO updates to 4'b0101, PISO finishes shifting out
        serial_in = 0; #20;

        // Cycle 6: Hold extra cycle to observe final outputs clearly
        #20;

        $finish;
    end
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# Add sources to project, configure top modules, and launch simulation
# ------------------------------------------------------------------------------
add_files -norecurse -fileset sources_1 [list $f_siso $f_piso]
add_files -norecurse -fileset sim_1     [list $f_tb]

set_property top siso_sipo_registers [get_filesets sources_1]
set_property top tb_shift_registers  [get_filesets sim_1]
set_property top_lib xil_defaultlib  [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "INFO: Project created at $proj_dir/$proj_name.xpr"
launch_simulation
