module Game(
    input i_clk,
    input i_rst_n,
    input [9:0] x,
    input [9:0] y,
    output [7:0] o_vga_r,
    output [7:0] o_vga_g,
    output [7:0] o_vga_b
);

// use 10*20 3'b registers store block colors
logic [2:0] blocks [0:9][0:19];

always_comb begin
    if ((x >= 9'd220) && (x <= 9'd420) && (y >= 9'd40) && (y <= 9'd440)) begin
        if (((x-220)%20 == 0) || ((y-40)%20 == 0)) begin
            o_vga_r = 8'd20;
            o_vga_g = 8'd20;
            o_vga_b = 8'd20;
        end
        else begin
            o_vga_r = 8'd255;
            o_vga_g = 8'd255;
            o_vga_b = 8'd0;
        end
    end
    else begin
        o_vga_r = 8'd20;
        o_vga_g = 8'd20;
        o_vga_b = 8'd20;
    end
end


endmodule