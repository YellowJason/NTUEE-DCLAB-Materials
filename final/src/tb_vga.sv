`timescale 1ns/10ps

module tb;
	localparam CLK = 40;
	localparam HCLK = CLK/2;

    logic clk, rst_n;
    wire [7:0] vga_r, vga_g, vga_b;
    wire vga_hs, vga_vs, vga_blank, vga_sync, vga_clk;

	initial clk = 0;
	always #HCLK clk = ~clk;

    vga vga0(
        .clk(clk),
        .rst_n(rst_n),
        .o_vga_r(vga_r),
        .o_vga_g(vga_g),
        .o_vga_b(vga_b),
        .o_vga_hs(vga_hs),
        .o_vga_vs(vga_vs),
        .o_vga_blank(vga_blank),
        .o_vga_sync(vga_sync),
        .o_vga_clk(vga_clk)
    );
    
	initial begin
        $fsdbDumpfile("vga.fsdb");
		$fsdbDumpvars;
        rst_n = 1;
		#(2*CLK)
		rst_n = 0;
		#(2*CLK)
        rst_n = 1;

        #(500*CLK)
        $display("vga simulation finish");
        $finish;
	end

endmodule