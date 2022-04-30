module Game(
    input i_clk,
    input i_rst_n,
    input [9:0] x,
    input [9:0] y,
    output [7:0] o_vga_r,
    output [7:0] o_vga_g,
    output [7:0] o_vga_b
);

// use 10*20 3'b registers store every blocks' color
logic [2:0] blocks [0:9][0:19];

// determine current (x,y) in which block
logic [3:0] x_block;
logic [4:0] y_block;
logic [2:0] color_code;
assign x_block = (x-220) / 20;
assign y_block = (y-40) / 20;
assign color_code = blocks[x_block][y_block];

// decoded color
logic [7:0] r_dec, g_dec, b_dec;
ColorDecoder dec0(
    .code(color_code),
    .r(r_dec),
    .g(g_dec),
    .b(b_dec)
);

always_comb begin
    if ((x >= 9'd220) && (x <= 9'd420) && (y >= 9'd40) && (y <= 9'd440)) begin
        // block boundary
        if (((x-220)%20 == 0) || ((y-40)%20 == 0)) begin
            o_vga_r = 8'd20;
            o_vga_g = 8'd20;
            o_vga_b = 8'd20;
        end
        // blocks
        else begin
            o_vga_r = r_dec;
            o_vga_g = g_dec;
            o_vga_b = b_dec;
        end
    end
    else begin
        o_vga_r = 8'd20;
        o_vga_g = 8'd20;
        o_vga_b = 8'd20;
    end
end

integer i;
integer j;
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        for (i=0; i<20; i++) begin
            blocks[0][i] <= 3'd1;
            blocks[1][i] <= 3'd2;
            blocks[2][i] <= 3'd3;
            blocks[3][i] <= 3'd4;
            blocks[4][i] <= 3'd5;
            blocks[5][i] <= 3'd6;
            blocks[6][i] <= 3'd7;
            blocks[7][i] <= 3'd0;
            blocks[8][i] <= 3'd1;
            blocks[9][i] <= 3'd2;
        end
    end
    else begin
        for (i=0; i<10; i++) begin
            for (j=0; j<20; j++) begin
                blocks[i][j] <= blocks[i][j];
            end
        end
    end
end
endmodule

// 8 colors decoder
module ColorDecoder(
    input [2:0] code,
    output [7:0] r,
    output [7:0] g,
    output [7:0] b
);

always_comb begin
    case(code)
        0: {r, g, b} = {8'd20,  8'd20,  8'd20 };
        1: {r, g, b} = {8'd255, 8'd20,  8'd20 };
        2: {r, g, b} = {8'd20,  8'd255, 8'd20 };
        3: {r, g, b} = {8'd20,  8'd20,  8'd255};
        4: {r, g, b} = {8'd20,  8'd255, 8'd255};
        5: {r, g, b} = {8'd255, 8'd20,  8'd255};
        6: {r, g, b} = {8'd255, 8'd255, 8'd20 };
        7: {r, g, b} = {8'd255, 8'd255, 8'd255}; 
    endcase
end

endmodule