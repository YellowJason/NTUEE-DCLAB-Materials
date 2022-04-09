`timescale 1ns/10ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

    logic rst, clk, start, fin, sclk, oen;
    wire sdat;

	initial clk = 0;
	always #HCLK clk = ~clk;


    I2CInitializer i2cInitializer(
        .i_rst_n(rst),
        .i_clk(clk),      
        .i_start(start),    // control if start

        .o_finished(fin),
        .o_sclk(sclk),      // s clock for i2c
        .o_sdat(sdat),      // data in / out
        .o_oen(oen)         // you are outputing (you are not outputing only when you are "ack"ing.)
    );

	initial begin
        $fsdbDumpfile("i2cInitializer.fsdb");
		$fsdbDumpvars;
        $display("reset i2c ...");
        rst = 1;
		#(2*CLK)
		rst = 0;
		#(2*CLK)
        $display("start i2cInitializer ...");
        rst=1;
        start = 1;
        #CLK
        // start = 0;
        @(posedge fin)
        $display("finish i2cInitializer");
		#(10*CLK)
        $finish;
	end

    initial begin
		#(5000000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
