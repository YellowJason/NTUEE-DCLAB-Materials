`timescale 1ns/10ps

module tb;
    // reg and data

	localparam CLK = 10;
	localparam HCLK = CLK/2;

    localparam DACLRCK = 400;
	localparam BIG_HCLK = DACLRCK/2;
    
    logic rst, clk, start, pause, stop, daclrck;
    logic [2:0] speed;
    logic [1:0] mode;
    logic [19:0] last_mem;
    logic [19:0] sram_addr;
    logic [15:0] sram_data;
    logic [15:0] dac_data;
    assign sram_data = {sram_addr[11:0], 4'b0};

	initial clk = 0;
    initial daclrck = 0;
	always #HCLK clk = ~clk;
    always #BIG_HCLK daclrck = ~daclrck;

    AudDSP dsp0(
        .i_rst_n        (rst),
        .i_clk          (clk),
        .i_start        (start),
        .i_pause        (pause),
        .i_stop         (stop),
        .i_speed        (speed),
        .mode           (mode),
        .i_daclrck      (daclrck),
        .i_last_mem     (last_mem),
        .i_sram_data    (sram_data),
        .o_dac_data     (dac_data),
        .o_sram_addr    (sram_addr)
    );

    initial begin        
        $fsdbDumpfile("dsp.fsdb");
		$fsdbDumpvars;
        $display("reset dsp ...");
        rst = 1;
        start = 0;
        pause = 0;
        stop = 0;
        speed = 2;  // change speed here
        mode = 3;   // change mode here
        last_mem = 0;

		#(2*CLK)
		rst = 0;
        #(CLK)
        rst = 1;
        #(CLK)
        start = 1;
        #(CLK)
        start = 0;
        
        #(100000*CLK)
        $finish;
	end

    initial begin
		#(500000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
