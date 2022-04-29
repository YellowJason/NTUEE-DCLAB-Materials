	component altpll is
		port (
			clk_clk       : in  std_logic := 'X'; -- clk
			reset_reset_n : in  std_logic := 'X'; -- reset_n
			altpll_25_clk : out std_logic;        -- clk
			altpll_65_clk : out std_logic         -- clk
		);
	end component altpll;

	u0 : component altpll
		port map (
			clk_clk       => CONNECTED_TO_clk_clk,       --       clk.clk
			reset_reset_n => CONNECTED_TO_reset_reset_n, --     reset.reset_n
			altpll_25_clk => CONNECTED_TO_altpll_25_clk, -- altpll_25.clk
			altpll_65_clk => CONNECTED_TO_altpll_65_clk  -- altpll_65.clk
		);

