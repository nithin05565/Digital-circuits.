# ==============================================================================
# Vivado 2024.1 Auto-Build Script for Experiment 11
# 4-Bit Asynchronous Ripple Counter & Synchronous Mod-10 Up/Down Counter
# ==============================================================================

# Close any open simulation or project safely
catch {close_sim -force}
if {[llength [get_projects -quiet]] > 0} {
    close_project
}

# Project settings (path has no spaces for Vivado compatibility)
set proj_name "exp11_counters"
set proj_dir  "C:/Vivado_Projects/exp11_counters"
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
# 1. Design Source: ripple_counter_4bit.v (with T Flip-Flop stage delay = 2ns)
# ------------------------------------------------------------------------------
set f_rip "$src_dir/ripple_counter_4bit.v"
set fh [open $f_rip "w"]
puts $fh {`timescale 1ns / 1ps

module ripple_counter_4bit (
    input  wire       clk,
    input  wire       rst,
    output wire [3:0] q,
    output wire [3:0] q_bar
);
    t_flip_flop ff0 (.clk(clk),      .rst(rst), .q(q[0]), .q_bar(q_bar[0]));
    t_flip_flop ff1 (.clk(q_bar[0]), .rst(rst), .q(q[1]), .q_bar(q_bar[1]));
    t_flip_flop ff2 (.clk(q_bar[1]), .rst(rst), .q(q[2]), .q_bar(q_bar[2]));
    t_flip_flop ff3 (.clk(q_bar[2]), .rst(rst), .q(q[3]), .q_bar(q_bar[3]));
endmodule

module t_flip_flop (
    input  wire clk,
    input  wire rst,
    output reg  q,
    output wire q_bar
);
    assign q_bar = ~q;

    always @(posedge clk or posedge rst) begin
        if (rst)
            q <= #2 1'b0;
        else
            q <= #2 ~q;
    end
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# 2. Design Source: sync_mod10_updown.v (Synchronous Mod-10 BCD Up/Down Counter)
# ------------------------------------------------------------------------------
set f_sync "$src_dir/sync_mod10_updown.v"
set fh [open $f_sync "w"]
puts $fh {`timescale 1ns / 1ps

module sync_mod10_updown (
    input  wire       clk,
    input  wire       rst,
    input  wire       up_down, // 1 = Count Up, 0 = Count Down
    output reg  [3:0] count
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 4'b0000;
        end else begin
            if (up_down) begin
                if (count >= 4'b1001)
                    count <= 4'b0000;
                else
                    count <= count + 1'b1;
            end else begin
                if (count == 4'b0000)
                    count <= 4'b1001;
                else
                    count <= count - 1'b1;
            end
        end
    end
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# 3. Simulation Testbench: tb_counter_systems.v
# ------------------------------------------------------------------------------
set f_tb "$src_dir/tb_counter_systems.v"
set fh [open $f_tb "w"]
puts $fh {`timescale 1ns / 1ps

module tb_counter_systems;
    reg        clk;
    reg        rst;
    reg        up_down;
    wire [3:0] q_ripple;
    wire [3:0] q_bar_ripple;
    wire [3:0] count_sync;

    ripple_counter_4bit uut_ripple (
        .clk(clk),
        .rst(rst),
        .q(q_ripple),
        .q_bar(q_bar_ripple)
    );

    sync_mod10_updown uut_sync (
        .clk(clk),
        .rst(rst),
        .up_down(up_down),
        .count(count_sync)
    );

    // 50 MHz Master Clock (20 ns period: 10 ns High, 10 ns Low)
    always #10 clk = ~clk;

    initial begin
        // Clean reset pulse so all flip-flops initialize reliably to 0000
        clk = 0; rst = 0; up_down = 1;
        #1 rst = 1;
        #6 rst = 0;

        // Count Up phase (shows Mod-10 rollover 9->0 and Ripple 0111->1000 delay)
        #220;

        // Switch to Count Down phase (shows Mod-10 wrap 0->9)
        up_down = 0;
        #200;

        // Final Reset check
        rst = 1;
        #40;

        $finish;
    end
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# Add sources to project, configure top modules, and launch simulation
# ------------------------------------------------------------------------------
add_files -norecurse -fileset sources_1 [list $f_rip $f_sync]
add_files -norecurse -fileset sim_1     [list $f_tb]

set_property top sync_mod10_updown  [get_filesets sources_1]
set_property top tb_counter_systems [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "INFO: Project created at $proj_dir/$proj_name.xpr"
launch_simulation
