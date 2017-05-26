LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ram IS
GENERIC(
  addr_bits  : POSITIVE := 10;
  data_bits  : POSITIVE := 32
);
PORT(
  clk        : IN  std_ulogic;
  address    : IN  std_ulogic_vector(addr_bits-1 DOWNTO 0);
  writedata  : IN  std_ulogic_vector(data_bits-1 DOWNTO 0);
  strobe     : IN  std_ulogic;
  wren       : IN  std_ulogic;
  readdata   : OUT std_ulogic_vector(data_bits-1 DOWNTO 0)
);
END ENTITY;

ARCHITECTURE infer OF ram IS

  SUBTYPE data_word IS std_ulogic_vector(data_bits-1 DOWNTO 0);
  TYPE data_array IS ARRAY (NATURAL RANGE <>) OF data_word;

  SIGNAL contents : data_array(0 TO 2**addr_bits-1);

BEGIN

  memory : PROCESS(clk)
    VARIABLE idx : NATURAL RANGE 0 TO 2**addr_bits-1;
  BEGIN
    IF rising_edge(clk) THEN
      IF strobe = '1' THEN
        idx := TO_INTEGER(UNSIGNED(address));
        IF wren = '1' THEN
          contents(idx) <= writedata;
        ELSE
          readdata <= contents(idx);
        END IF;
      END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE;

