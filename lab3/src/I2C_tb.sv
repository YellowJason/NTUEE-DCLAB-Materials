`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

    logic rst, clk, start, finishwd, sclk, sdat, oen;

	initial clk = 0;
	always #HCLK clk = ~clk;

    I2cInitializer i0(
        .i_rst_n(rst),
        .i_clk(clk),      
        .i_start(start),
        .o_finished(finished),
        .o_sclk(sclk),
        .o_sdat(sdat),
        .o_oen(oen)
    );

	initial begin
        $fsdbDumpfile("i2cInitializer.fsdb");
		$fsdbDumpvars;
        $display("I2C Initialize start");
        rst = 1;
		#(2*CLK)
		rst = 0;
		#(2*CLK)
        rst=1;
        #CLK
        start = 1;
        #CLK
        start = 0;
        @(posedge finished)
        $display("I2C Initialize finish");
		#(10*CLK)
        $finish;
	end

    initial begin
		#(10000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule