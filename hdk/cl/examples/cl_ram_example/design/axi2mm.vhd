LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY axi2mm IS
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
  axi_rready    : IN  std_ulogic;
  -- Memory Mapped Slave
  mm_ready      : IN  std_ulogic;
  mm_address    : OUT std_ulogic_vector(31 DOWNTO 0);
  mm_writedata  : OUT std_ulogic_vector(31 DOWNTO 0);
  mm_byteenable : OUT std_ulogic_vector( 3 DOWNTO 0);
  mm_strobe     : OUT std_ulogic;
  mm_wren       : OUT std_ulogic;
  mm_readdata   : IN  std_ulogic_vector(31 DOWNTO 0);
  mm_readvalid  : IN  std_ulogic
);
END ENTITY;

ARCHITECTURE fsm OF axi2mm IS

  TYPE state_t IS (idle, write_wait, writing, write_response, reading, read_wait, read_response);

  SIGNAL state    : state_t;

BEGIN

  -- Accept addresses when idle, but prioritise writes
  axi_awready <= '1' WHEN state = idle ELSE '0';
  axi_arready <= '1' WHEN state = idle AND axi_awvalid = '0' ELSE '0';

  -- Accept write data when in the correct state
  axi_wready  <= '1' WHEN state = write_wait ELSE '0';

  -- Provide write responses based on the state
  axi_bvalid  <= '1' WHEN state = write_response ELSE '0';
  axi_bresp   <= "00";

  -- Provide read responses based on the state
  axi_rvalid  <= '1' WHEN state = read_response ELSE '0';
  axi_rresp   <= "00";

  ctrl : PROCESS(clk, reset)
  BEGIN
    IF rising_edge(clk) THEN
      CASE state IS
        WHEN idle =>
          -- Wait for a request, prioritise writes over reads
          IF axi_awvalid = '1' THEN
            state <= write_wait;
            mm_address <= axi_awaddr;
          ELSIF axi_arvalid = '1' THEN
            state <= reading;
            mm_address <= axi_araddr;
          END IF;
        WHEN write_wait =>
          -- Wait for write data
          IF axi_wvalid = '1' THEN
            mm_writedata  <= axi_wdata;
            mm_byteenable <= axi_wstrb;
            state         <= writing;
          END IF;
        WHEN writing =>
          -- mm_strobe is asserted while in this state, wait for ack
          IF mm_ready = '1' THEN
            state        <= write_response;
          END IF;
        WHEN write_response =>
          -- Wait for acceptance of response
          IF axi_bready = '1' THEN
            state        <= idle;
          END IF;
        WHEN reading =>
          -- mm_strobe is asserted while in this state, wait for ack
          IF mm_ready = '1' THEN
            state        <= read_wait;
          END IF;
        WHEN read_wait =>
          -- Wait for data back from slave
          IF mm_readvalid = '1' THEN
            axi_rdata <= mm_readdata;
            state     <= read_response;
          END IF;
        WHEN read_response =>
          -- Wait for acceptance of response
          IF axi_rready = '1' THEN
            state <= idle;
          END IF;
      END CASE;
    END IF;
    IF reset = '1' THEN
      state   <= idle;
    END IF;
  END PROCESS;

  mm_strobe <= '1' WHEN state = writing OR state = reading ELSE '0';
  mm_wren   <= '1' WHEN state = writing ELSE '0';

END ARCHITECTURE;

