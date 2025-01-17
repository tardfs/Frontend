library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_signed.all ;
use ieee.std_logic_arith.all ;

entity ad9978ctl is
  port (
   reset   : in std_logic ; --  async reset
   clk     : in std_logic ; 
   SL      : out std_logic ; -- SL signal
   SDATA   : out std_logic ; -- SDATA signal
   SCK     : out std_logic ; -- SCK signal
   HD      : out std_logic ; -- HD signal
   VD      : out std_logic ; -- VD signal
   init_done    :out std_logic 
   ) ;
end ad9978ctl ;

architecture arc_ad9978ctl of ad9978ctl is
component ad9978port
  port (
    
   reset        : in std_logic ;
   clk          : in std_logic ; 
   ch_data_addr : in std_logic_vector(23 downto 0) ;
   wr           : in std_logic ;

   sl      : out std_logic ; -- SL signal
   sdata   : out std_logic ; -- SDATA signal
   sck     : out std_logic -- SCK signal
   
 ) ;
end component ;

type cmd_mem_type is array (0 to 8) of std_logic_vector(23 downto 0) ;
constant cmd_mem: cmd_mem_type := 
(
  b"1111_000000000001_01010000", -- write 1 to 0x50 (software reset)
  b"1111_000100000000_01000001", -- write 0x100 to 0x41 (startup1)
  b"1111_010000000000_01001110", -- write 0x40 to bits 11:4 of 0x4E (startup2)
  b"1111_010000000000_01001111", -- write 0x80 to bits 11:3 of 0x4F (startup3)
  b"1111_000001100000_11101001", -- write 0x60 to 0xE9 (startup4)
  
  b"01000001_000100000010_1111", -- write 0x82 to 0x41
  b"00000000_000000000000_1111",
  b"00000000_000000000000_1111",
  b"00000000_000000000000_1111"
) ;
type cmd_timings_type is array (0 to 8) of integer range 0 to 2048 ;
constant cmd_timings: cmd_timings_type :=  -- x20ns
(
32, 32, 32, 32, 100, 100, 100, 100, 100
) ;
signal cmd_addr : integer range 0 to 255 := 0 ; 
type state_type is (StateReadCmd,StateExec,StateWait,StateIdle) ;
signal state: state_type := StateIdle ;
signal count: integer range 0 to 16367 ;
signal cmd: std_logic_vector(23 downto 0) ;
signal wr: std_logic := '0' ;

begin

conf_port:ad9978port
   port map (
      reset => reset,
      clk => clk,
      ch_data_addr => cmd,
      wr => wr,
      sl => sl,
      sdata => sdata,
      sck => sck 
 ) ;

process(clk)
begin
   if reset='1' then 
      state <= StateWait ;
      count <= 10 ;
      cmd_addr <= 0 ;
      init_done <= '0' ;
      wr <= '0' ;
   elsif rising_edge(clk) then
      case state is
      when StateReadCmd =>
         wr <= '0' ;
         if cmd_addr<cmd_mem'length then
            cmd <= cmd_mem(cmd_addr) ;
            count <= cmd_timings(cmd_addr) ;
            state <= StateExec ;
            cmd_addr <= cmd_addr + 1 ;
         else
            state <= StateIdle ;
         end if ;
      when StateExec =>
         wr <= '1' ;
         state <= StateWait ;
      when StateWait =>
         wr <= '0' ;
         if count>0 then
            count <= count - 1 ;
         else
            state <= StateReadCmd ;
         end if ;
      when StateIdle =>
         init_done <= '1' ;
      end case ;
   end if ;
end process ;
end architecture arc_ad9978ctl ;
