LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY wrapped_axi_ram IS
GENERIC(
  addr_bits     : POSITIVE := 10
);
PORT(
  clk           : IN  std_ulogic;
  reset         : IN  std_ulogic;
  -- AXI Master Write Address
  axi_awvalid   : IN  std_ulogic;
  axi_awaddr    : IN  std_ulogic_vector(31 DOWNTO 0);
  axi_awready   : OUT std_ulogic;
  -- AXI Master Write Data
  axi_wvalid    : IN  std_ulogic;
  axi_wdata     : IN  std_ulogic_vector(31 DOWNTO 0);
  axi_wstrb     : IN  std_ulogic_vector( 3 DOWNTO 0);
  axi_wready    : OUT std_ulogic;
  -- AXI Master Write Response
  axi_bvalid    : OUT std_ulogic;
  axi_bresp     : OUT std_ulogic_vector( 1 DOWNTO 0);
  axi_bready    : IN  std_ulogic;
  -- AXI Master Read Address
  axi_arvalid   : IN  std_ulogic;
  axi_araddr    : IN  std_ulogic_vector(31 DOWNTO 0);
  axi_arready   : OUT std_ulogic;
  -- AXI Master Read Data/Response
  axi_rvalid    : OUT std_ulogic;
  axi_rdata     : OUT std_ulogic_vector(31 DOWNTO 0);
  axi_rresp     : OUT std_ulogic_vector( 1 DOWNTO 0);
  axi_rready    : IN  std_ulogic
);
END ENTITY;

ARCHITECTURE structure OF wrapped_axi_ram IS

  SIGNAL ready      : std_ulogic;
  SIGNAL address    : std_ulogic_vector(31 DOWNTO 0);
  SIGNAL writedata  : std_ulogic_vector(31 DOWNTO 0);
  SIGNAL byteenable : std_ulogic_vector( 3 DOWNTO 0);
  SIGNAL strobe     : std_ulogic;
  SIGNAL wren       : std_ulogic;
  SIGNAL readdata   : std_ulogic_vector(31 DOWNTO 0);
  SIGNAL readvalid  : std_ulogic;

BEGIN

  axi2mm : ENTITY work.axi2mm
  PORT MAP(
    clk           => clk,
    reset         => reset,
    -- AXI Master Write Address
    axi_awvalid   => axi_awvalid,
    axi_awaddr    => axi_awaddr,
    axi_awready   => axi_awready,
    -- AXI Master Write Data
    axi_wvalid    => axi_wvalid,
    axi_wdata     => axi_wdata,
    axi_wstrb     => axi_wstrb,
    axi_wready    => axi_wready,
    -- AXI Master Write Response
    axi_bvalid    => axi_bvalid,
    axi_bresp     => axi_bresp,
    axi_bready    => axi_bready,
    -- AXI Master Read Address
    axi_arvalid   => axi_arvalid,
    axi_araddr    => axi_araddr,
    axi_arready   => axi_arready,
    -- AXI Master Read Data/Response
    axi_rvalid    => axi_rvalid,
    axi_rdata     => axi_rdata,
    axi_rresp     => axi_rresp,
    axi_rready    => axi_rready,
    -- Memory Mapped Slave
    mm_ready      => ready,
    mm_address    => address,
    mm_writedata  => writedata,
    mm_byteenable => byteenable,
    mm_strobe     => strobe,
    mm_wren       => wren,
    mm_readdata   => readdata,
    mm_readvalid  => readvalid
  );

  -- Non blocking:
  ready <= strobe;

  -- One RAM per byte
  ram_gen : FOR i IN 3 DOWNTO 0 GENERATE
    SIGNAL local_wren : std_ulogic;
  BEGIN
    local_wren <= wren AND byteenable(i);

    ram_inst : ENTITY work.ram
    GENERIC MAP(
      addr_bits  => addr_bits,
      data_bits  => 8
    )
    PORT MAP(
      clk        => clk,
      address    => address,
      writedata  => writedata(i*8+7 DOWNTO i*8),
      strobe     => strobe,
      wren       => local_wren,
      readdata   => readdata(i*8+7 DOWNTO i*8)
    );

  END GENERATE;

  -- Calculate return data validity
  validate : PROCESS(clk, reset)
  BEGIN
    IF reset = '1' THEN
      readvalid <= '0';
    ELSIF rising_edge(clk) THEN
      readvalid <= strobe AND ready AND NOT wren;
    END IF;
  END PROCESS;

END ARCHITECTURE;

