`timescale 1ns/10ps

module tb;
	localparam CLK = 20;
	localparam HCLK = CLK/2;
    localparam HCLK_ps2 = 100;

    logic clk, rst_n, i_data, ps2_clk;
    wire [7:0] o_data;
    wire finish;

	initial clk = 0;
	always #HCLK clk = ~clk;

    Keyboard keyboard0(
        .i_clk(clk),
        .i_rst_n(rst_n),
        .i_data(i_data),
        .i_ps2_clk(ps2_clk),
        .o_data(o_data),
        .o_finish(finish)
    );

	initial begin
        $fsdbDumpfile("keyboard.fsdb");
		$fsdbDumpvars;
        rst_n = 1;
		#(2*CLK)
		rst_n = 0;
		#(2*CLK)
        rst_n = 1;

        @(posedge finish)
        $display("reading finish");
		#(30*CLK)
        $finish;
	end
    
    initial begin
        // data 1
        i_data = 1;
        #(10*CLK)
        i_data = 0;
        #(6*HCLK_ps2)
        i_data = 1;
        #(6*HCLK_ps2)
        i_data = 0;
        #(8*HCLK_ps2)
        i_data = 1;

        // data 2
        #(10*CLK)
        i_data = 0;
        #(4*HCLK_ps2)
        i_data = 1;
        #(8*HCLK_ps2)
        i_data = 0;
        #(8*HCLK_ps2)
        i_data = 1;
    end

    parameter iter = 22;
    initial begin
        ps2_clk = 1;
        #(10*CLK)
        repeat (iter) begin
            #(HCLK_ps2)
            ps2_clk = ~ps2_clk;
        end

        #(8*CLK)
        repeat (iter) begin
            #(HCLK_ps2)
            ps2_clk = ~ps2_clk;
        end
    end

    initial begin
		#(1000*CLK)
		$display("Too slow, abort.");
		$finish;
	end
endmodule