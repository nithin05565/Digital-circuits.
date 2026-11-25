# ==============================================================================
# Vivado 2024.1 Auto-Build Script for Experiment 19
# Behavioral Verilog Co-Model: NMOS & PMOS I-V Characteristics
# Models Transfer (ID vs VGS) and Output (ID vs VDS) sweeps using Square-Law
# equations with |Vth| = 700 mV, kn = 200 uA/V^2, kp = 100 uA/V^2.
# ==============================================================================

catch {close_sim -force}
if {[llength [get_projects -quiet]] > 0} {
    close_project
}

set proj_name "exp19_mosfet_iv"
set proj_dir  "C:/Vivado_Projects/exp19_mosfet_iv"
set part_name "xc7a35tcpg236-1"

file mkdir $proj_dir
create_project $proj_name $proj_dir -part $part_name -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

set src_dir "$proj_dir/hdl_sources"
file mkdir $src_dir

# ------------------------------------------------------------------------------
# 1. Design Source: mosfet_iv_char.v (NMOS & PMOS Square-Law I-V Co-Model)
# ------------------------------------------------------------------------------
set f_des "$src_dir/mosfet_iv_char.v"
set fh [open $f_des "w"]
puts $fh {`timescale 1ns / 1ps

module mosfet_iv_char (
    input  wire        is_pmos,    // 0 = NMOS, 1 = PMOS (uses voltage magnitudes)
    input  wire [12:0] vgs_mv,     // |V_GS| in mV (0 to 5000 mV)
    input  wire [12:0] vds_mv,     // |V_DS| in mV (0 to 5000 mV)
    output reg  [1:0]  op_region,  // 00 = Cutoff, 01 = Linear, 10 = Saturation
    output reg  [15:0] id_ua       // Modeled |I_D| in microamps (uA)
);
    localparam [63:0] VTH_MV = 64'd700; // |V_th| = 0.70 V
    localparam [63:0] KN_UA  = 64'd200; // NMOS transconductance parameter (uA/V^2)
    localparam [63:0] KP_UA  = 64'd100; // PMOS transconductance parameter (uA/V^2)

    reg [63:0] vov;
    reg [63:0] vds;
    reg [63:0] k_val;
    reg [63:0] id_calc;

    always @(*) begin
        k_val   = is_pmos ? KP_UA : KN_UA;
        vds     = {51'd0, vds_mv};
        vov     = 64'd0;
        id_calc = 64'd0;

        if ({51'd0, vgs_mv} < VTH_MV) begin
            // Cutoff Region: |V_GS| < |V_th|
            op_region = 2'b00;
            id_ua     = 16'd0;
        end else begin
            vov = {51'd0, vgs_mv} - VTH_MV;
            if (vds < vov) begin
                // Linear (Triode) Region: |V_DS| < |V_GS| - |V_th|
                op_region = 2'b01;
                id_calc   = (k_val * ((64'd2 * vov * vds) - (vds * vds))) / 64'd2000000;
                id_ua     = id_calc[15:0];
            end else begin
                // Saturation Region: |V_DS| >= |V_GS| - |V_th|
                op_region = 2'b10;
                id_calc   = (k_val * vov * vov) / 64'd2000000;
                id_ua     = id_calc[15:0];
            end
        end
    end
endmodule
}
close $fh

# ------------------------------------------------------------------------------
# 2. Simulation Testbench: tb_mosfet_iv_char.v (Transfer & Output Sweeps)
# ------------------------------------------------------------------------------
set f_tb "$src_dir/tb_mosfet_iv_char.v"
set fh [open $f_tb "w"]
puts $fh {`timescale 1ns / 1ps

module tb_mosfet_iv_char;
    reg         is_pmos;
    reg  [12:0] vgs_mv;
    reg  [12:0] vds_mv;
    wire [1:0]  op_region;
    wire [15:0] id_ua;

    mosfet_iv_char uut (
        .is_pmos(is_pmos),
        .vgs_mv(vgs_mv),
        .vds_mv(vds_mv),
        .op_region(op_region),
        .id_ua(id_ua)
    );

    integer step;

    initial begin
        $display("================================================================");
        $display(" Experiment 19: NMOS & PMOS I-V Characteristics (|Vth| = 700 mV)");
        $display(" Region Codes: 00 = Cutoff, 01 = Linear, 10 = Saturation");
        $display("================================================================");

        // Phase 1: NMOS Transfer Characteristics (ID vs VGS at VDS = 3000 mV)
        $display("\n--- Phase 1: NMOS Transfer Sweep (VDS = 3000 mV) ---");
        $display("VGS(mV) | VDS(mV) | Region | ID(uA)");
        is_pmos = 1'b0;
        vds_mv  = 13'd3000;
        for (step = 0; step <= 3000; step = step + 500) begin
            vgs_mv = step[12:0];
            #10;
            $display("  %4d  |  %4d   |   %b   |  %4d", vgs_mv, vds_mv, op_region, id_ua);
        end

        // Phase 2: NMOS Output Characteristics (ID vs VDS at VGS = 2000 mV)
        $display("\n--- Phase 2: NMOS Output Sweep (VGS = 2000 mV, Vov = 1300 mV) ---");
        $display("VGS(mV) | VDS(mV) | Region | ID(uA)");
        is_pmos = 1'b0;
        vgs_mv  = 13'd2000;
        for (step = 0; step <= 3000; step = step + 500) begin
            vds_mv = step[12:0];
            #10;
            $display("  %4d  |  %4d   |   %b   |  %4d", vgs_mv, vds_mv, op_region, id_ua);
        end

        // Phase 3: PMOS Transfer Characteristics (|ID| vs |VGS| at |VDS| = 3000 mV)
        $display("\n--- Phase 3: PMOS Transfer Sweep (|VDS| = 3000 mV) ---");
        $display("|VGS|(mV) | |VDS|(mV) | Region | |ID|(uA)");
        is_pmos = 1'b1;
        vds_mv  = 13'd3000;
        for (step = 0; step <= 3000; step = step + 500) begin
            vgs_mv = step[12:0];
            #10;
            $display("   %4d   |   %4d    |   %b   |   %4d", vgs_mv, vds_mv, op_region, id_ua);
        end

        // Phase 4: PMOS Output Characteristics (|ID| vs |VDS| at |VGS| = 2000 mV)
        $display("\n--- Phase 4: PMOS Output Sweep (|VGS| = 2000 mV, |Vov| = 1300 mV) ---");
        $display("|VGS|(mV) | |VDS|(mV) | Region | |ID|(uA)");
        is_pmos = 1'b1;
        vgs_mv  = 13'd2000;
        for (step = 0; step <= 3000; step = step + 500) begin
            vds_mv = step[12:0];
            #10;
            $display("   %4d   |   %4d    |   %b   |   %4d", vgs_mv, vds_mv, op_region, id_ua);
        end

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

set_property top mosfet_iv_char    [get_filesets sources_1]
set_property top tb_mosfet_iv_char [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "INFO: Project created at $proj_dir/$proj_name.xpr"
launch_simulation
