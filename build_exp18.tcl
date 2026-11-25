# ==============================================================================
# Vivado 2024.1 Auto-Build Script for Experiment 18
# 16x4 RAM and 16x4 ROM Memory Organization (VHDL)
# ==============================================================================

catch {close_sim -force}
if {[llength [get_projects -quiet]] > 0} {
    close_project
}

set proj_name "exp18_ram_rom_16x4"
set proj_dir  "C:/Vivado_Projects/exp18_ram_rom_16x4"
set part_name "xc7a35tcpg236-1"

file mkdir $proj_dir
create_project $proj_name $proj_dir -part $part_name -force
set_property target_language VHDL [current_project]
set_property simulator_language Mixed [current_project]

set src_dir "$proj_dir/hdl_sources"
file mkdir $src_dir

# ------------------------------------------------------------------------------
# 1. Design Source: ram_16x4.vhd (16x4 Synchronous-Write, Async-Read RAM)
# ------------------------------------------------------------------------------
set f_ram "$src_dir/ram_16x4.vhd"
set fh [open $f_ram "w"]
puts $fh {library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ram_16x4 is
    Port (
        clk  : in  std_logic;
        we   : in  std_logic;
        addr : in  std_logic_vector(3 downto 0);
        din  : in  std_logic_vector(3 downto 0);
        dout : out std_logic_vector(3 downto 0)
    );
end ram_16x4;

architecture rtl of ram_16x4 is
    type mem_t is array (0 to 15) of std_logic_vector(3 downto 0);
    signal mem : mem_t := (others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                mem(to_integer(unsigned(addr))) <= din;
            end if;
        end if;
    end process;

    dout <= mem(to_integer(unsigned(addr)));
end rtl;
}
close $fh

# ------------------------------------------------------------------------------
# 2. Design Source: rom_16x4.vhd (16x4 Combinational Lookup ROM)
# ------------------------------------------------------------------------------
set f_rom "$src_dir/rom_16x4.vhd"
set fh [open $f_rom "w"]
puts $fh {library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rom_16x4 is
    Port (
        addr : in  std_logic_vector(3 downto 0);
        dout : out std_logic_vector(3 downto 0)
    );
end rom_16x4;

architecture rtl of rom_16x4 is
    type rom_t is array (0 to 15) of std_logic_vector(3 downto 0);
    constant rom_mem : rom_t := (
        0  => "0001",
        1  => "0100",
        2  => "0111",
        3  => "1010",
        4  => "1101",
        5  => "0000",
        6  => "0011",
        7  => "0110",
        8  => "1001",
        9  => "1100",
        10 => "1111",
        11 => "0010",
        12 => "0101",
        13 => "1000",
        14 => "1011",
        15 => "1110"
    );
begin
    dout <= rom_mem(to_integer(unsigned(addr)));
end rtl;
}
close $fh

# ------------------------------------------------------------------------------
# 3. Simulation Testbench: tb_ram_rom_16x4.vhd
# ------------------------------------------------------------------------------
set f_tb "$src_dir/tb_ram_rom_16x4.vhd"
set fh [open $f_tb "w"]
puts $fh {library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_ram_rom_16x4 is
end tb_ram_rom_16x4;

architecture sim of tb_ram_rom_16x4 is
    signal clk      : std_logic := '0';
    signal we       : std_logic := '0';
    signal addr     : std_logic_vector(3 downto 0) := (others => '0');
    signal din      : std_logic_vector(3 downto 0) := (others => '0');
    signal ram_dout : std_logic_vector(3 downto 0);
    signal rom_dout : std_logic_vector(3 downto 0);
begin
    -- 10 ns clock period (rising edges at 5 ns, 15 ns, 25 ns, ...)
    clk <= not clk after 5 ns;

    uut_ram: entity work.ram_16x4(rtl)
        port map (
            clk  => clk,
            we   => we,
            addr => addr,
            din  => din,
            dout => ram_dout
        );

    uut_rom: entity work.rom_16x4(rtl)
        port map (
            addr => addr,
            dout => rom_dout
        );

    stim: process
    begin
        -- Offset 2 ns so inputs settle 3 ns before each rising clock edge
        wait for 2 ns;

        -- Write 4 distinct words to RAM addresses 0..3
        we <= '1';
        addr <= "0000"; din <= "1010"; wait for 10 ns;
        addr <= "0001"; din <= "0101"; wait for 10 ns;
        addr <= "0010"; din <= "1100"; wait for 10 ns;
        addr <= "0011"; din <= "0011"; wait for 10 ns;

        -- Disable write (we = 0) and read back RAM addresses 0..3
        we <= '0'; din <= "0000";
        addr <= "0000"; wait for 10 ns;
        addr <= "0001"; wait for 10 ns;
        addr <= "0010"; wait for 10 ns;
        addr <= "0011"; wait for 10 ns;

        -- Sweep remaining addresses 4..15 to verify full 16x4 ROM contents
        for i in 4 to 15 loop
            addr <= std_logic_vector(to_unsigned(i, 4));
            wait for 10 ns;
        end loop;

        wait;
    end process;
end sim;
}
close $fh

# ------------------------------------------------------------------------------
# Add sources to project, configure top modules, and launch simulation
# ------------------------------------------------------------------------------
add_files -norecurse -fileset sources_1 [list $f_ram $f_rom]
add_files -norecurse -fileset sim_1     [list $f_tb]

set_property top ram_16x4           [get_filesets sources_1]
set_property top tb_ram_rom_16x4    [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set_property -name {xsim.simulate.runtime} -value {205ns} -objects [get_filesets sim_1]

puts "INFO: Project created at $proj_dir/$proj_name.xpr"
launch_simulation
