`timescale 1us/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

    logic rst, clk, start, finishwd, sclk, oen;
    logic [7:0] num;
    wire sdat;

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
        start = 0;
		#(2*CLK)
		rst = 0;
		#(2*CLK)
        rst=1;
        start = 1;
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
    
    parameter iter = 10000;
    initial begin
        num = 0;
        #55
        repeat (iter) begin
            #CLK
            if (sclk) begin
                if (oen) begin
                    $display("num=%3d, dat=%0b", num, sdat);
                    num = num + 1;
                end
                else begin
                    $display("wait acknowledge");
                end
            end
        end
    end

endmodule