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

// update counter
logic [23:0] counter_update;

// center of the moving shape
logic [3:0] x_center;
logic [4:0] y_center;
logic [3:0] b1_x, b2_x, b3_x;
logic [4:0] b1_y, b2_y, b3_y;
ShapeDecoder shape0(
    .center_x(x_center),
    .center_y(y_center),
    .shape(3'b1),
    .b1_x(b1_x),
    .b2_x(b2_x),
    .b3_x(b3_x),
    .b1_y(b1_y),
    .b2_y(b2_y),
    .b3_y(b3_y)
);
// if current coordinate in the moving shape
logic in_shape;
assign in_shape = (x_block == x_center && y_block == y_center) ||
                  (x_block == b1_x && y_block == b1_y) ||
                  (x_block == b2_x && y_block == b2_y) ||
                  (x_block == b3_x && y_block == b3_y);

always_comb begin
    if ((x >= 9'd220) && (x <= 9'd420) && (y >= 9'd40) && (y <= 9'd440)) begin
        // block boundary
        if (((x-220)%20 == 0) || ((y-40)%20 == 0)) begin
            o_vga_r = 8'd20;
            o_vga_g = 8'd20;
            o_vga_b = 8'd20;
        end
        // moving shape
        else if (in_shape) begin
            o_vga_r = 8'd200;
            o_vga_g = 8'd200;
            o_vga_b = 8'd200;
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
        x_center <= 4'd4;
        y_center <= 5'd0;
    end
    else begin
        for (i=0; i<10; i++) begin
            for (j=0; j<20; j++) begin
                blocks[i][j] <= blocks[i][j];
            end
        end
        // update moving shape
        counter_update <= counter_update + 1;
        if (counter_update == ~24'b0) begin
            y_center <= y_center + 1;
            x_center <= x_center;
        end
        else begin
            y_center <= y_center;
            x_center <= x_center;
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

module ShapeDecoder(
    input [3:0] center_x,
    input [4:0] center_y,
    input [2:0] shape,
    output [3:0] b1_x,
    output [3:0] b2_x,
    output [3:0] b3_x,
    output [4:0] b1_y,
    output [4:0] b2_y,
    output [4:0] b3_y
);

always_comb begin
    case(shape)
        1: begin  //OO
                 //  OO
            b1_x = center_x-1;
            b2_x = center_x;
            b3_x = center_x+1;
            b1_y = center_y;
            b2_y = center_y+1;
            b3_y = center_y+1;
        end
        2: begin  // 　O
                  //  OO
                  //  O
            b1_x = center_x;
            b2_x = center_x-1;
            b3_x = center_x-1;
            b1_y = center_y-1;
            b2_y = center_y;
            b3_y = center_y+1; 
        end
        3: begin  // O
                  // OO
                  //  O
            b1_x = center_x;
            b2_x = center_x+1;
            b3_x = center_x+1;
            b1_y = center_y-1;
            b2_y = center_y;
            b3_y = center_y+1;
        end
        4: begin  //OO
                // OO
            b1_x = center_x-1;
            b2_x = center_x;
            b3_x = center_x+1;
            b1_y = center_y;
            b2_y = center_y-1;
            b3_y = center_y-1;
        end
        5:begin //O
             //  OOO
            b1_x = center_x-1;
            b2_x = center_x;
            b3_x = center_x+1;
            b1_y = center_y;
            b2_y = center_y-1;
            b3_y = center_y;
        end
        6:begin //O
              // OO
                //O
            b1_x = center_x-1;
            b2_x = center_x;
            b3_x = center_x;
            b1_y = center_y;
            b2_y = center_y-1;
            b3_y = center_y+1;
        end
        7:begin // OOO
                //  O
            b1_x = center_x-1;
            b2_x = center_x;
            b3_x = center_x+1;
            b1_y = center_y;
            b2_y = center_y+1;
            b3_y = center_y;
        end
        8: begin //O
                // OO
                // O
            b1_x = center_x;
            b2_x = center_x+1;
            b3_x = center_x;
            b1_y = center_y-1;
            b2_y = center_y;
            b3_y = center_y+1;
        end
        9: begin //OOOO
            b1_x = center_x-1;
            b2_x = center_x+1;
            b3_x = center_x+2;
            b1_y = center_y;
            b2_y = center_y;
            b3_y = center_y;
        end
        10: begin //O
                  //O
                  //O
                  //O
            b1_x = center_x;
            b2_x = center_x;
            b3_x = center_x;
            b1_y = center_y-1;
            b2_y = center_y+1;
            b3_y = center_y+2;
        end
        11: begin //O
                  //O
                // OO
            b1_x = center_x-1;
            b2_x = center_x;
            b3_x = center_x;
            b1_y = center_y+1;
            b2_y = center_y-1;
            b3_y = center_y+1;
        end
        12: begin // OOO
                  //   O
            b1_x = center_x-1;
            b2_x = center_x+1;
            b3_x = center_x+1;
            b1_y = center_y;
            b2_y = center_y;
            b3_y = center_y+1;
        end
        13: begin  //OO
                   //O
                   //O
            b1_x = center_x;
            b2_x = center_x;
            b3_x = center_x+1;
            b1_y = center_y-1;
            b2_y = center_y+1;
            b3_y = center_y-1;
        end
        14:begin   //O
                   //OOO
            b1_x = center_x-1;
            b2_x = center_x-1;
            b3_x = center_x+1;
            b1_y = center_y-1;
            b2_y = center_y;
            b3_y = center_y;
        end
        15:begin  //O
               // OOO
            b1_x = center_x-1;
            b2_x = center_x+1;
            b3_x = center_x+1;
            b1_y = center_y;
            b2_y = center_y;
            b3_y = center_y-1;
        end
        16:begin  // OO
                  //  O
                  //  O
            b1_x = center_x-1;
            b2_x = center_x;
            b3_x = center_x;
            b1_y = center_y-1;
            b2_y = center_y-1;
            b3_y = center_y+1;
        end
        17:begin //OOO
                 //O
            b1_x = center_x-1;
            b2_x = center_x-1;
            b3_x = center_x+1;
            b1_y = center_y;
            b2_y = center_y+1;
            b3_y = center_y;
        end
        18:begin  //OO
                  //OO
            b1_x = center_x;
            b2_x = center_x+1;
            b3_x = center_x+1;
            b1_y = center_y+1;
            b2_y = center_y;
            b3_y = center_y+1;
        end
        19:begin  //O
                  //O
                  //OO
            b1_x = center_x;
            b2_x = center_x;
            b3_x = center_x+1;
            b1_y = center_y-1;
            b2_y = center_y+1;
            b3_y = center_y+1;
        end
        default: begin
            b1_x = center_x-1;
            b2_x = center_x;
            b3_x = center_x+1;
            b1_y = center_y;
            b2_y = center_y+1;
            b3_y = center_y+1;
        end
    endcase
end

endmodule