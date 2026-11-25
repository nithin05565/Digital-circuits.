# ==============================================================================
# Vivado 2024.1 Auto-Build Script for Experiment 10
# SR, D, JK, T, and Master-Slave JK Flip-Flops (Verilog HDL)
# ==============================================================================

# Close any open simulation or project safely
catch {close_sim -force}
if {[llength [get_projects -quiet]] > 0} {
    close_project
}

# Project settings (path has no spaces for Vivado compatibility)
set proj_name "exp10_flipflops"
set proj_dir  "C:/Vivado_Projects/exp10_flipflops"
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
# 1. Design Source: flip_flops.v (SR, D, JK, T Flip-Flops)
# ------------------------------------------------------------------------------
set f_ff "$src_dir/flip_flops.v"
set fh [open $f_ff "w"]
puts $fh {`timescale 1ns / 1ps

module flip_flops (
    input  wire       clk,
    input  wire       rst,
    input  wire [1:0] inputs, // {S, R} for SR FF; {J, K} for JK FF
    input  wire       d,
    input  wire       t,
    output reg        q_sr,
    output reg        q_d,
    output reg        q_jk,
    output reg        q_t
);

    // SR Flip-Flop Behavioral Block
    always @(posedge clk or posedge rst) begin
        if (rst)
            q_sr <= 1'b0;
        else begin
            case (inputs)
                2'b00: q_sr <= q_sr;
                2'b01: q_sr <= 1'b0;
                2'b10: q_sr <= 1'b1;
                2'b11: q_sr <= 1'bx;
            endcase
        end
    end

    // D Flip-Flop Behavioral Block
    always @(posedge clk or posedge rst) begin
        if (rst)
            q_d <= 1'b0;
        else
            q_d <= d;
    end

    // JK Flip-Flop Behavioral Block
    always @(posedge clk or posedge rst) begin
        if (rst)
            q_jk <= 1'b0;
        else begin
            case (inputs)
                2'b00: q_jk <= q_jk;
                2'b01: q_jk <= 1'b0;
                2'b10: q_jk <= 1'b1;
                2'b11: q_jk <= ~q_jk;
            endcase
        end
    end

    // T Flip-Flop Behavioral Block
    always @(posedge clk or posedge rst) begin
        if (rst)
            q_t <= 1'b0;
        else begin
            if (t)
                q_t <= ~q_t;
            else
                q_t <= q_t;
        end
    end

endmodule
}
close $fh

# ------------------------------------------------------------------------------
# 2. Design Source: master_slave_jk.v (Master-Slave JK Flip-Flop)
# ------------------------------------------------------------------------------
set f_ms "$src_dir/master_slave_jk.v"
set fh [open $f_ms "w"]
puts $fh {`timescale 1ns / 1ps

module master_slave_jk (
    input  wire clk,
    input  wire rst,
    input  wire j,
    input  wire k,
    output reg  q,
    output wire q_bar
);
    reg q_master;

    // Master Stage: Sensitive to positive edge
    always @(posedge clk or posedge rst) begin
        if (rst)
            q_master <= 1'b0;
        else begin
            case ({j, k})
                2'b00: q_master <= q_master;
                2'b01: q_master <= 1'b0;
                2'b10: q_master <= 1'b1;
                2'b11: q_master <= ~q; // Feedback from master-slave output
            endcase
        end
    end

    // Slave Stage: Sensitive to negative edge
    always @(negedge clk or posedge rst) begin
        if (rst)
            q <= 1'b0;
        else
            q <= q_master;
    end

    assign q_bar = ~q;

endmodule
}
close $fh

# ------------------------------------------------------------------------------
# 3. Simulation Testbench: tb_flip_flops.v
# ------------------------------------------------------------------------------
set f_tb "$src_dir/tb_flip_flops.v"
set fh [open $f_tb "w"]
puts $fh {`timescale 1ns / 1ps

module tb_flip_flops;
    reg       clk;
    reg       rst;
    reg [1:0] inputs;
    reg       d;
    reg       t;
    reg       j, k;

    wire q_sr, q_d, q_jk, q_t;
    wire q_ms, q_ms_bar;

    flip_flops uut_core (
        .clk(clk),
        .rst(rst),
        .inputs(inputs),
        .d(d),
        .t(t),
        .q_sr(q_sr),
        .q_d(q_d),
        .q_jk(q_jk),
        .q_t(q_t)
    );

    master_slave_jk uut_ms (
        .clk(clk),
        .rst(rst),
        .j(j),
        .k(k),
        .q(q_ms),
        .q_bar(q_ms_bar)
    );

    // 20 ns Clock Period (10 ns High, 10 ns Low)
    always #10 clk = ~clk;

    initial begin
        clk = 0; rst = 1; inputs = 2'b00; d = 0; t = 0; j = 0; k = 0;
        #15 rst = 0;

        // Set State
        inputs = 2'b10; d = 1; t = 1; j = 1; k = 0; #20;

        // Reset State
        inputs = 2'b01; d = 0; t = 0; j = 0; k = 1; #20;

        // Toggle Mode (Race prevention check)
        inputs = 2'b11; t = 1; j = 1; k = 1; #40;

        // Hold Mode
        inputs = 2'b00; t = 0; j = 0; k = 0; #20;

        $finish;
    end
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# Add sources to project, configure top modules, and launch simulation
# ------------------------------------------------------------------------------
add_files -norecurse -fileset sources_1 [list $f_ff $f_ms]
add_files -norecurse -fileset sim_1     [list $f_tb]

set_property top flip_flops    [get_filesets sources_1]
set_property top tb_flip_flops [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "INFO: Project created at $proj_dir/$proj_name.xpr"
launch_simulation
