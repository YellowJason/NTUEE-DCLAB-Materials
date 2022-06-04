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
        7: {r, g, b} = {8'd255, 8'd100, 8'd0  };
    endcase
end

endmodule

module ShapeDecoder(
    input [3:0] center_x,
    input [4:0] center_y,
    input [2:0] shape,
    input [1:0] direction,
    output [3:0] b1_x,
    output [3:0] b2_x,
    output [3:0] b3_x,
    output [4:0] b1_y,
    output [4:0] b2_y,
    output [4:0] b3_y
);

always_comb begin
    case(shape)
        0: begin  
            case(direction[0])
                0: begin // OO
                         //  OO
                    b1_x = center_x-1;
                    b2_x = center_x;
                    b3_x = center_x+1;
                    b1_y = center_y;
                    b2_y = center_y+1;
                    b3_y = center_y+1;
                end
                1: begin //  O
                         // OO
                         // O
                b1_x = center_x;
                b2_x = center_x-1;
                b3_x = center_x-1;
                b1_y = center_y-1;
                b2_y = center_y;
                b3_y = center_y+1; 
                end
            endcase
        end

        1: begin                   
            case(direction[0])
                0: begin //  OO
                         // OO
                    b1_x = center_x-1;
                    b2_x = center_x;
                    b3_x = center_x+1;
                    b1_y = center_y+1;
                    b2_y = center_y+1;
                    b3_y = center_y;
                end
                1: begin // O         
                         // OO
                         //  O
                    b1_x = center_x-1;
                    b2_x = center_x-1;
                    b3_x = center_x;
                    b1_y = center_y-1;
                    b2_y = center_y;
                    b3_y = center_y+1;
                end
            endcase
        end
        
        2: begin
            case(direction)
                0: begin // OOO
                         //  O
                    b1_x = center_x-1;
                    b2_x = center_x;
                    b3_x = center_x+1;
                    b1_y = center_y;
                    b2_y = center_y+1;
                    b3_y = center_y;
                end
                1: begin //O
                       // OO
                         //O
                    b1_x = center_x-1;
                    b2_x = center_x;
                    b3_x = center_x;
                    b1_y = center_y;
                    b2_y = center_y-1;
                    b3_y = center_y+1;
                end
                2: begin  //O
                        // OOO
                    b1_x = center_x-1;
                    b2_x = center_x;
                    b3_x = center_x+1;
                    b1_y = center_y;
                    b2_y = center_y-1;
                    b3_y = center_y;
                end
                3: begin //O
                        // OO
                        // O
                    b1_x = center_x;
                    b2_x = center_x+1;
                    b3_x = center_x;
                    b1_y = center_y-1;
                    b2_y = center_y;
                    b3_y = center_y+1;
                end
            endcase
        end
        
        3: begin
            case(direction[0])
                0: begin //OOOO
                    b1_x = center_x-1;
                    b2_x = center_x+1;
                    b3_x = center_x+2;
                    b1_y = center_y;
                    b2_y = center_y;
                    b3_y = center_y;
                end
                1: begin //O
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
            endcase
        end

        4: begin
            case(direction)
                0: begin  // OOO
                          //   O
                    b1_x = center_x-1;
                    b2_x = center_x+1;
                    b3_x = center_x+1;
                    b1_y = center_y;
                    b2_y = center_y;
                    b3_y = center_y+1;
                end
                1: begin  //O
                          //O
                        // OO
                    b1_x = center_x-1;
                    b2_x = center_x;
                    b3_x = center_x;
                    b1_y = center_y+1;
                    b2_y = center_y-1;
                    b3_y = center_y+1;
                end
                2: begin  //O
                          //OOO
                    b1_x = center_x-1;
                    b2_x = center_x-1;
                    b3_x = center_x+1;
                    b1_y = center_y-1;
                    b2_y = center_y;
                    b3_y = center_y;
                end
                3: begin  //OO
                          //O
                          //O
                    b1_x = center_x;
                    b2_x = center_x;
                    b3_x = center_x+1;
                    b1_y = center_y-1;
                    b2_y = center_y+1;
                    b3_y = center_y-1;
                end
            endcase
        end

        5: begin
            case(direction)
                0: begin //OOO
                         //O
                    b1_x = center_x-1;
                    b2_x = center_x-1;
                    b3_x = center_x+1;
                    b1_y = center_y;
                    b2_y = center_y+1;
                    b3_y = center_y;
                end
                1: begin  // OO
                          //  O
                          //  O
                    b1_x = center_x-1;
                    b2_x = center_x;
                    b3_x = center_x;
                    b1_y = center_y-1;
                    b2_y = center_y-1;
                    b3_y = center_y+1;
                end
                2: begin   //O
                        // OOO
                    b1_x = center_x-1;
                    b2_x = center_x+1;
                    b3_x = center_x+1;
                    b1_y = center_y;
                    b2_y = center_y;
                    b3_y = center_y-1;
                end
                3: begin  //O
                          //O
                          //OO
                    b1_x = center_x;
                    b2_x = center_x;
                    b3_x = center_x+1;
                    b1_y = center_y-1;
                    b2_y = center_y+1;
                    b3_y = center_y+1;
                end
            endcase
        end

        6: begin   //OO
                   //OO
            b1_x = center_x;
            b2_x = center_x+1;
            b3_x = center_x+1;
            b1_y = center_y+1;
            b2_y = center_y;
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

module shape_show_box (
    input [2:0] shape,
    output logic [15:0] shape_show
);
    always_comb begin
        case(shape)
            0: shape_show = 16'b0000_0110_0011_0000; //z
            1: shape_show = 16'b0000_0011_0110_0000; //s
            2: shape_show = 16'b0000_0010_0111_0000; //t
            3: shape_show = 16'b0000_1111_0000_0000; //i
            4: shape_show = 16'b0000_0100_0111_0000; //j
            5: shape_show = 16'b0000_0001_0111_0000; //l
            6: shape_show = 16'b0000_0110_0110_0000; //o
            7: shape_show = 16'b0000_0000_0000_0000;
        endcase
    end
endmodule

module ScoreDecoder (
	input        [9:0] score,
	output logic [20:0] score_7_hex
);

/* The layout of seven segment display, 1: dark
 *    00
 *   5  1
 *    66
 *   4  2
 *    33
 */
parameter D0 = ~7'b1000000;
parameter D1 = ~7'b1111001;
parameter D2 = ~7'b0100100;
parameter D3 = ~7'b0110000;
parameter D4 = ~7'b0011001;
parameter D5 = ~7'b0010010;
parameter D6 = ~7'b0000010;
parameter D7 = ~7'b1011000;
parameter D8 = ~7'b0000000;
parameter D9 = ~7'b0010000;

logic [3:0] first, second, third;
assign third = score / 10'd100;
assign second = (score - third*10'd100) / 10'd10;
assign first = score - third*10'd100 - second*10'd10;

always_comb begin
	case(first)
		4'h0: score_7_hex[6:0] = D0;
		4'h1: score_7_hex[6:0] = D1;
		4'h2: score_7_hex[6:0] = D2;
		4'h3: score_7_hex[6:0] = D3;
		4'h4: score_7_hex[6:0] = D4;
		4'h5: score_7_hex[6:0] = D5;
		4'h6: score_7_hex[6:0] = D6;
		4'h7: score_7_hex[6:0] = D7;
		4'h8: score_7_hex[6:0] = D8;
		4'h9: score_7_hex[6:0] = D9;
        default: score_7_hex[6:0] = D0;
	endcase
    case(second)
		4'h0: score_7_hex[13:7] = D0;
		4'h1: score_7_hex[13:7] = D1;
		4'h2: score_7_hex[13:7] = D2;
		4'h3: score_7_hex[13:7] = D3;
		4'h4: score_7_hex[13:7] = D4;
		4'h5: score_7_hex[13:7] = D5;
		4'h6: score_7_hex[13:7] = D6;
		4'h7: score_7_hex[13:7] = D7;
		4'h8: score_7_hex[13:7] = D8;
		4'h9: score_7_hex[13:7] = D9;
        default: score_7_hex[13:7] = D0;
	endcase
    case(third)
		4'h0: score_7_hex[20:14] = D0;
		4'h1: score_7_hex[20:14] = D1;
		4'h2: score_7_hex[20:14] = D2;
		4'h3: score_7_hex[20:14] = D3;
		4'h4: score_7_hex[20:14] = D4;
		4'h5: score_7_hex[20:14] = D5;
		4'h6: score_7_hex[20:14] = D6;
		4'h7: score_7_hex[20:14] = D7;
		4'h8: score_7_hex[20:14] = D8;
		4'h9: score_7_hex[20:14] = D9;
        default: score_7_hex[20:14] = D0;
	endcase
end

endmodule