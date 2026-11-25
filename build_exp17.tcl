# ==============================================================================
# Vivado 2024.1 Auto-Build Script for Experiment 17
# Behavioral Verilog Co-Model: TTL (74LS04) vs CMOS (74HC04) Characteristics
# Note: Vivado is a digital simulator; voltages/currents/delays are modeled
# behaviorally from standard 5.0 V datasheet parameters at f = 1 MHz.
# ==============================================================================

catch {close_sim -force}
if {[llength [get_projects -quiet]] > 0} {
    close_project
}

set proj_name "exp17_ttl_cmos"
set proj_dir  "C:/Vivado_Projects/exp17_ttl_cmos"
set part_name "xc7a35tcpg236-1"

file mkdir $proj_dir
create_project $proj_name $proj_dir -part $part_name -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

set src_dir "$proj_dir/hdl_sources"
file mkdir $src_dir

# ------------------------------------------------------------------------------
# 1. Design Source: ttl_cmos_char.v (Behavioral TTL 74LS04 & CMOS 74HC04 Model)
# ------------------------------------------------------------------------------
set f_des "$src_dir/ttl_cmos_char.v"
set fh [open $f_des "w"]
puts $fh {`timescale 1ns / 1ps

module ttl_cmos_char (
    input  wire        vin,
    input  wire [4:0]  load_count,    // Fan-out load count N (1, 2, 5, 10, ...)
    output reg         y_ttl,         // 74LS04 logic output
    output reg         y_cmos,        // 74HC04 logic output
    output wire [12:0] vout_ttl_mv,   // Modeled TTL output voltage (mV)
    output wire [12:0] vout_cmos_mv,  // Modeled CMOS output voltage (mV)
    output wire [12:0] power_ttl_uw,  // Modeled TTL power dissipation (uW)
    output wire [12:0] power_cmos_uw  // Modeled CMOS power dissipation (uW)
);
    // Standard 5.0 V datasheet nominal voltages (mV)
    localparam [12:0] TTL_VOH_MV  = 13'd3400; // 3.40 V typical (min 2.7 V)
    localparam [12:0] TTL_VOL_MV  = 13'd350;  // 0.35 V typical (max 0.5 V)
    localparam [12:0] CMOS_VOH_MV = 13'd4950; // 4.95 V typical (min 4.9 V)
    localparam [12:0] CMOS_VOL_MV = 13'd50;   // 0.05 V typical (max 0.1 V)

    // Initialize outputs for vin = 0 at t = 0
    initial begin
        y_ttl  = 1'b1;
        y_cmos = 1'b1;
    end

    // TTL 74LS04 propagation delay model (base tPLH = 9 ns, tPHL = 10 ns)
    // Slight delay increase as fan-out load increases
    always @(vin) begin
        if (vin == 1'b0)
            y_ttl <= #(9 + (load_count >> 1)) 1'b1;
        else
            y_ttl <= #(10 + (load_count >> 1)) 1'b0;
    end

    // CMOS 74HC04 propagation delay model (base tPLH = 7 ns, tPHL = 7 ns)
    // Capacitive fan-out loading scales delay more noticeably in CMOS
    always @(vin) begin
        if (vin == 1'b0)
            y_cmos <= #(7 + (load_count * 2)) 1'b1;
        else
            y_cmos <= #(7 + (load_count * 2)) 1'b0;
    end

    // Voltage level mapping (in mV)
    assign vout_ttl_mv  = y_ttl  ? TTL_VOH_MV  : TTL_VOL_MV;
    assign vout_cmos_mv = y_cmos ? CMOS_VOH_MV : CMOS_VOL_MV;

    // Power dissipation model at 5.0 V, 1 MHz (in uW)
    // TTL draws higher static power (~2000 uW); CMOS draws low power scaling with C_L
    assign power_ttl_uw  = (y_ttl ? 13'd1000 : 13'd3000) + (load_count * 13'd50);
    assign power_cmos_uw = 13'd10 + (load_count * 13'd125);
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# 2. Simulation Testbench: tb_ttl_cmos.v (1 MHz Input + Load Count Sweep)
# ------------------------------------------------------------------------------
set f_tb "$src_dir/tb_ttl_cmos.v"
set fh [open $f_tb "w"]
puts $fh {`timescale 1ns / 1ps

module tb_ttl_cmos;
    reg         vin;
    reg  [4:0]  load_count;
    wire        y_ttl;
    wire        y_cmos;
    wire [12:0] vout_ttl_mv;
    wire [12:0] vout_cmos_mv;
    wire [12:0] power_ttl_uw;
    wire [12:0] power_cmos_uw;

    ttl_cmos_char uut (
        .vin(vin),
        .load_count(load_count),
        .y_ttl(y_ttl),
        .y_cmos(y_cmos),
        .vout_ttl_mv(vout_ttl_mv),
        .vout_cmos_mv(vout_cmos_mv),
        .power_ttl_uw(power_ttl_uw),
        .power_cmos_uw(power_cmos_uw)
    );

    initial begin
        $display("=====================================================================");
        $display(" Experiment 17: TTL (74LS04) vs CMOS (74HC04) at VCC = 5.0 V, f = 1 MHz");
        $display("---------------------------------------------------------------------");
        $display(" TTL  (74LS04): VOH(min)=2.7V, VOL(max)=0.5V, VIH=2.0V, VIL=0.8V");
        $display("                NMH = 0.7V, NML = 0.3V, Base tp = 9.5 ns");
        $display(" CMOS (74HC04): VOH(min)=4.9V, VOL(max)=0.1V, VIH=3.5V, VIL=1.5V");
        $display("                NMH = 1.4V, NML = 1.4V, Base tp = 7.0 ns");
        $display("=====================================================================");
        $display("Time(ns) | Load N | Vin | Y_TTL(mV) | Y_CMOS(mV) | P_TTL(uW) | P_CMOS(uW)");

        // Cycle 1: Standard single load (N = 1) at 1 MHz (500 ns low, 500 ns high)
        load_count = 5'd1;
        vin = 1'b0; #500;
        $display("%8t |   %2d   |  %b  |   %4d    |    %4d    |   %4d    |    %4d",
                 $time, load_count, vin, vout_ttl_mv, vout_cmos_mv, power_ttl_uw, power_cmos_uw);
        vin = 1'b1; #500;
        $display("%8t |   %2d   |  %b  |   %4d    |    %4d    |   %4d    |    %4d",
                 $time, load_count, vin, vout_ttl_mv, vout_cmos_mv, power_ttl_uw, power_cmos_uw);

        // Cycle 2: Medium fan-out load (N = 5)
        load_count = 5'd5;
        vin = 1'b0; #500;
        $display("%8t |   %2d   |  %b  |   %4d    |    %4d    |   %4d    |    %4d",
                 $time, load_count, vin, vout_ttl_mv, vout_cmos_mv, power_ttl_uw, power_cmos_uw);
        vin = 1'b1; #500;
        $display("%8t |   %2d   |  %b  |   %4d    |    %4d    |   %4d    |    %4d",
                 $time, load_count, vin, vout_ttl_mv, vout_cmos_mv, power_ttl_uw, power_cmos_uw);

        // Cycle 3: Heavy fan-out load (N = 10)
        load_count = 5'd10;
        vin = 1'b0; #500;
        $display("%8t |   %2d   |  %b  |   %4d    |    %4d    |   %4d    |    %4d",
                 $time, load_count, vin, vout_ttl_mv, vout_cmos_mv, power_ttl_uw, power_cmos_uw);
        vin = 1'b1; #500;
        $display("%8t |   %2d   |  %b  |   %4d    |    %4d    |   %4d    |    %4d",
                 $time, load_count, vin, vout_ttl_mv, vout_cmos_mv, power_ttl_uw, power_cmos_uw);

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

set_property top ttl_cmos_char [get_filesets sources_1]
set_property top tb_ttl_cmos   [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set_property -name {xsim.simulate.runtime} -value {3100ns} -objects [get_filesets sim_1]

puts "INFO: Project created at $proj_dir/$proj_name.xpr"
launch_simulation
