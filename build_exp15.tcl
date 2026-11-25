# ==============================================================================
# Vivado 2024.1 Auto-Build Script for Experiment 15
# 4-Bit Synchronous Counter Using VHDL and IEEE 1164 Logic Types
# ==============================================================================

catch {close_sim -force}
if {[llength [get_projects -quiet]] > 0} {
    close_project
}

set proj_name "exp15_vhdl_sync_counter"
set proj_dir  "C:/Vivado_Projects/exp15_vhdl_sync_counter"
set part_name "xc7a35tcpg236-1"

file mkdir $proj_dir
create_project $proj_name $proj_dir -part $part_name -force
set_property target_language VHDL [current_project]
set_property simulator_language Mixed [current_project]

set src_dir "$proj_dir/hdl_sources"
file mkdir $src_dir

# ------------------------------------------------------------------------------
# 1. Design Source: sync_counter_4bit.vhd (4-Bit Synchronous Counter)
# ------------------------------------------------------------------------------
set f_des "$src_dir/sync_counter_4bit.vhd"
set fh [open $f_des "w"]
puts $fh {library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sync_counter_4bit is
    Port (
        clk   : in  std_logic;
        reset : in  std_logic;
        en    : in  std_logic;
        q     : out std_logic_vector(3 downto 0)
    );
end sync_counter_4bit;

architecture rtl of sync_counter_4bit is
    signal count : unsigned(3 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                count <= (others => '0');
            elsif en = '1' then
                count <= count + 1;
            end if;
        end if;
    end process;

    q <= std_logic_vector(count);
end rtl;
}
close $fh

# ------------------------------------------------------------------------------
# 2. Simulation Testbench: tb_sync_counter_4bit.vhd
# ------------------------------------------------------------------------------
set f_tb "$src_dir/tb_sync_counter_4bit.vhd"
set fh [open $f_tb "w"]
puts $fh {library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_sync_counter_4bit is
end tb_sync_counter_4bit;

architecture sim of tb_sync_counter_4bit is
    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
    signal en    : std_logic := '0';
    signal q     : std_logic_vector(3 downto 0);
begin
    -- 10 ns clock period (100 MHz)
    clk <= not clk after 5 ns;

    uut: entity work.sync_counter_4bit(rtl)
        port map (
            clk   => clk,
            reset => reset,
            en    => en,
            q     => q
        );

    stim: process
    begin
        wait for 12 ns;
        reset <= '0';
        en    <= '1';
        wait for 50 ns;
        en    <= '0';
        wait for 20 ns;
        reset <= '1';
        wait for 10 ns;
        reset <= '0';
        en    <= '1';
        wait for 30 ns;
        wait;
    end process;
end sim;
}
close $fh

# ------------------------------------------------------------------------------
# Add sources to project, configure top modules, and launch simulation
# ------------------------------------------------------------------------------
add_files -norecurse -fileset sources_1 [list $f_des]
add_files -norecurse -fileset sim_1     [list $f_tb]

set_property top sync_counter_4bit    [get_filesets sources_1]
set_property top tb_sync_counter_4bit [get_filesets sim_1]
set_property top_lib xil_defaultlib   [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Run for 122 ns to cover the full testbench stimulus cleanly
set_property -name {xsim.simulate.runtime} -value {122ns} -objects [get_filesets sim_1]

puts "INFO: Project created at $proj_dir/$proj_name.xpr"
launch_simulation
