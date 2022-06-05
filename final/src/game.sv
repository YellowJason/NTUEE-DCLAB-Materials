module Game(
    input i_clk,
    input i_rst_n,
    input i_start,
    input i_stop,
    input [9:0] x,
    input [9:0] y,
    input [7:0] i_key,
    input [2:0] i_attack,
    output [2:0] o_state,
    output logic [2:0] o_delete,
    output logic o_finish,
    // output [7:0] o_score
    output [7:0] o_vga_r,
    output [7:0] o_vga_g,
    output [7:0] o_vga_b
);

integer i;
integer j;

// states
parameter S_IDLE = 3'd0; // state before start
parameter S_WAIT = 3'd1; // Wait key action
parameter S_EVAL = 3'd2; // evaluate if the key is workable
parameter S_STAL = 3'd3; // stall a little time after update
parameter S_END  = 3'd4; // evaluate if the block reach bottom
parameter S_DELE = 3'd5; // delete full rows
parameter S_ATTK = 3'd6; // add garbage row
logic [2:0] state, state_nxt;
assign o_state = state;

// output buffer
logic [7:0] vga_r, vga_r_n, vga_g, vga_g_n, vga_b, vga_b_n;
assign o_vga_r = vga_r;
assign o_vga_g = vga_g;
assign o_vga_b = vga_b;

// keyboard in
parameter up = 8'h75;
parameter down = 8'h29;
parameter right = 8'h74;
parameter left = 8'h6b;
parameter speed = 8'h72;
parameter hold = 8'h5a;
parameter esc = 8'h76;

// use 10*20 3'b registers store every blocks' color
logic [2:0] blocks [0:9][0:19];
logic [2:0] blocks_nxt [0:9][0:19];

// determine current (x,y) in which block
logic [3:0] x_block;
logic [4:0] y_block;
logic [2:0] color_code;
assign x_block = (x-230) / 18;
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

// score
logic [9:0] score, score_nxt;
logic [20:0] score_7_hex;
logic [2:0] delete_count, delete_count_nxt;
logic [2:0] o_delete_nxt;
logic o_finish_nxt;
// assign o_score = score[7:0];
ScoreDecoder score_decoder(
	.score(score),
	.score_7_hex(score_7_hex)
);

// update counter
logic [24:0] counter_update, counter_update_nxt;

// stall counter
logic [21:0] counter_stall, counter_stall_nxt;

// row delete counter
logic [4:0] counter_delete, counter_delete_nxt;

// the moving shape
logic [3:0] x_center, x_center_nxt;
logic [4:0] y_center, y_center_nxt;
logic [3*7-1:0] shape_list, shape_list_nxt;     // shape shift register
logic [2:0] counter_shape, counter_shape_nxt;   // counter if go throygh 7 shapes
logic [2:0] shape, shape_nxt;                   // current shape
// assign shape = shape_list[20:18];
logic [1:0] dirc, dirc_nxt;
logic [3:0] b1_x, b2_x, b3_x;
logic [4:0] b1_y, b2_y, b3_y;
ShapeDecoder shape0(
    .center_x(x_center),
    .center_y(y_center),
    .shape(shape),
    .direction(dirc),
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

// the lowest position of current shape
logic [4:0] y_low, y_low_nxt;
logic [3:0] b1_x_low, b2_x_low, b3_x_low;
logic [4:0] b1_y_low, b2_y_low, b3_y_low;
logic down_valid;
ShapeDecoder shape1(
    .center_x(x_center),
    .center_y(y_low),
    .shape(shape),
    .direction(dirc),
    .b1_x(b1_x_low),
    .b2_x(b2_x_low),
    .b3_x(b3_x_low),
    .b1_y(b1_y_low),
    .b2_y(b2_y_low),
    .b3_y(b3_y_low)
);

assign down_valid = (blocks[b1_x_low][b1_y_low+1] == 3'b0) &&
                    (blocks[b2_x_low][b2_y_low+1] == 3'b0) &&
                    (blocks[b3_x_low][b3_y_low+1] == 3'b0) &&
                    (blocks[x_center][y_low+1] == 3'b0) &&
                    (b1_y_low+1 <= 5'd19) &&
                    (b2_y_low+1 <= 5'd19) &&
                    (b3_y_low+1 <= 5'd19) &&
                    (y_low+1 <= 5'd19);

// if current coordinate in the moving shape
logic in_low;
assign in_low = (x_block == x_center && y_block == y_low) ||
                  (x_block == b1_x_low && y_block == b1_y_low) ||
                  (x_block == b2_x_low && y_block == b2_y_low) ||
                  (x_block == b3_x_low && y_block == b3_y_low);

// text of hold
logic hold_text;
assign hold_text = (x==10'd131 && y>=10'd130 && y<10'd150) || (x>=10'd131 && x<10'd145 && y==10'd140) || (x==10'd145 && y>=10'd130 && y<10'd150) //H
                 ||(x==10'd149 && y>=10'd130 && y<10'd150) || (x>=10'd149 && x<10'd163 && y==10'd130) || (x>=10'd149 && x<10'd163 && y==10'd150) || (x==10'd163 && y>=10'd130 && y<=10'd150) //O
                 ||(x==10'd167 && y>=10'd130 && y<10'd150) || (x>=10'd167 && x<10'd181 && y==10'd150) //L
                 ||(x==10'd185 && y>=10'd130 && y<10'd150) || (x>=10'd185 && x<10'd199 && y==5*(x-185)/14+130) || (x>=10'd185 && x<10'd199 && y==150-5*(x-185)/14) || (x==10'd199 && y>=10'd135 && y<=10'd145); //D
// show hold shape
logic [2:0] shape_hold, shape_hold_nxt;
logic [1:0] x_hold, y_hold;
logic [15:0] shape_show;
assign x_hold = (x-10'd129) / 10'd18;
assign y_hold = (y-10'd160) / 10'd20;
shape_show_box show0(
    .shape(shape_hold),
    .shape_show(shape_show)
);

// next shape
logic [2:0] shape_next;
logic [1:0] x_next, y_next;
logic [15:0] shape_show_2;
assign shape_next = (counter_shape == 3'd6) ? shape_list[11:9] : shape_list[17:15];
assign x_next = (x-10'd129) / 10'd18;
assign y_next = (y-10'd280) / 10'd20;
shape_show_box show1(
    .shape(shape_next),
    .shape_show(shape_show_2)
);

// text of next
logic next_text;
assign next_text = (x==10'd131 && y>=10'd250 && y<10'd270) || (x>=10'd131 && x<10'd145 && y==10*(x-131)/7+250) || (x==10'd145 && y>=10'd250 && y<10'd270) //N
                 ||(x==10'd149 && y>=10'd250 && y<10'd270) || (x>=10'd149 && x<10'd163 && y==10'd250) || (x>=10'd149 && x<10'd163 && y==10'd260) || (x>=10'd149 && x<10'd163 && y==10'd270) //E
                 ||(x>=10'd167 && x<=10'd181 && y==10*(x-167)/7+250) || (x>=10'd167 && x<=10'd181 && y==270-10*(x-167)/7) //X
                 ||(x>=10'd185 && x<10'd199 && y==10'd250) || (x==10'd192 && y>=10'd250 && y<10'd270); //T

// attack
logic [2:0] attack_count, attack_count_nxt;
logic [9:0] rand_attk, rand_attk_nxt; // empty position of garbage row
logic [22:0] attack_bg_color, attack_bg_color_nxt;
always_comb begin
    rand_attk_nxt = rand_attk;
    // change background color
    if (i_attack > 3'd1) attack_bg_color_nxt = ~23'b0;
    else                 attack_bg_color_nxt = (attack_bg_color == 23'b0) ? 23'b0 : (attack_bg_color-1'b1);
    // count how many garbage row
    if ((state == S_ATTK) && (attack_count > 3'd0)) begin
        attack_count_nxt = attack_count - 1;
        rand_attk_nxt = {rand_attk[6:0], rand_attk[9:7]};
    end
    else if (state == S_IDLE) begin
        attack_count_nxt = 3'd0;
    end
    else if (i_attack != 3'd0) begin
        case(i_attack)
            2: attack_count_nxt = 3'd1;
            3: attack_count_nxt = 3'd2;
            4: attack_count_nxt = 3'd4;
            default: attack_count_nxt = 3'd0;
        endcase
    end
    else attack_count_nxt = attack_count;
end

// showing
always_comb begin
    // hold text
    if (((x>10'd145 && x<10'd149) || (x>10'd163 && x<10'd167) || (x>10'd181 && x<10'd185)) && (y>=10'd130 && y<10'd150)) begin
        vga_r_n = 8'd50;
        vga_g_n = 8'd50;
        vga_b_n = 8'd50;
    end
    else if (hold_text) begin
        vga_r_n = 8'd255;
        vga_g_n = 8'd255;
        vga_b_n = 8'd255;
    end
    // hold block
    else if ((x >= 10'd129) && (x <= 10'd201) && (y >= 10'd160) && (y <= 10'd240)) begin
        if (((x-10'd129)%10'd18 == 0) || ((y-10'd160)%10'd20 == 0)) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else begin
            if (shape_show[y_hold*4 + x_hold]) begin
                case(shape_hold)
                    0: {vga_r_n, vga_g_n, vga_b_n} = {8'd255, 8'd20,  8'd20 };
                    1: {vga_r_n, vga_g_n, vga_b_n} = {8'd20,  8'd255, 8'd20 };
                    2: {vga_r_n, vga_g_n, vga_b_n} = {8'd20,  8'd20,  8'd255};
                    3: {vga_r_n, vga_g_n, vga_b_n} = {8'd20,  8'd255, 8'd255};
                    4: {vga_r_n, vga_g_n, vga_b_n} = {8'd255, 8'd20,  8'd255};
                    5: {vga_r_n, vga_g_n, vga_b_n} = {8'd255, 8'd255, 8'd20 };
                    6: {vga_r_n, vga_g_n, vga_b_n} = {8'd255, 8'd100, 8'd0  };
                    7: {vga_r_n, vga_g_n, vga_b_n} = {8'd20,  8'd20,  8'd20 };
                endcase
            end
            else begin
                vga_r_n = 8'd20;
                vga_g_n = 8'd20;
                vga_b_n = 8'd20;
            end
        end
    end
    // next text
    else if (((x>10'd145 && x<10'd149) || (x>10'd163 && x<10'd167) || (x>10'd181 && x<10'd185)) && (y>=10'd250 && y<10'd270)) begin
        vga_r_n = 8'd50;
        vga_g_n = 8'd50;
        vga_b_n = 8'd50;
    end
    else if (next_text) begin
        vga_r_n = 8'd255;
        vga_g_n = 8'd255;
        vga_b_n = 8'd255;
    end
    // next block
    else if ((x >= 10'd129) && (x <= 10'd201) && (y >= 10'd280) && (y <= 10'd360)) begin
        if (((x-10'd129)%10'd18 == 0) || ((y-10'd280)%10'd20 == 0)) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else begin
            if (shape_show_2[y_next*4 + x_next]) begin
                case(shape_next)
                    0: {vga_r_n, vga_g_n, vga_b_n} = {8'd255, 8'd20,  8'd20 };
                    1: {vga_r_n, vga_g_n, vga_b_n} = {8'd20,  8'd255, 8'd20 };
                    2: {vga_r_n, vga_g_n, vga_b_n} = {8'd20,  8'd20,  8'd255};
                    3: {vga_r_n, vga_g_n, vga_b_n} = {8'd20,  8'd255, 8'd255};
                    4: {vga_r_n, vga_g_n, vga_b_n} = {8'd255, 8'd20,  8'd255};
                    5: {vga_r_n, vga_g_n, vga_b_n} = {8'd255, 8'd255, 8'd20 };
                    6: {vga_r_n, vga_g_n, vga_b_n} = {8'd255, 8'd100, 8'd0  };
                    7: {vga_r_n, vga_g_n, vga_b_n} = {8'd20,  8'd20,  8'd20 };
                endcase
            end
            else begin
                vga_r_n = 8'd20;
                vga_g_n = 8'd20;
                vga_b_n = 8'd20;
            end
        end
    end
    // game area
    else if ((x >= 10'd230) && (x <= 10'd410) && (y >= 10'd40) && (y <= 10'd440)) begin
        // block boundary
        if (((x-10'd230)%10'd18 == 0) || ((y-10'd40)%10'd20 == 0)) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        // moving shape
        else if (in_shape) begin
            if (shape+1 == 3'd1) {vga_r_n, vga_g_n, vga_b_n} = {8'd255, 8'd20,  8'd20 };
            else if (shape+1 == 3'd2) {vga_r_n, vga_g_n, vga_b_n} = {8'd20,  8'd255, 8'd20 };
            else if (shape+1 == 3'd3) {vga_r_n, vga_g_n, vga_b_n} = {8'd20,  8'd20,  8'd255};
            else if (shape+1 == 3'd4) {vga_r_n, vga_g_n, vga_b_n} = {8'd20,  8'd255, 8'd255};
            else if (shape+1 == 3'd5) {vga_r_n, vga_g_n, vga_b_n} = {8'd255, 8'd20,  8'd255};
            else if (shape+1 == 3'd6) {vga_r_n, vga_g_n, vga_b_n} = {8'd255, 8'd255, 8'd20 };
            else {vga_r_n, vga_g_n, vga_b_n} = {8'd255, 8'd100, 8'd0};
        end
        // lowest position
        else if (in_low) begin
            vga_r_n = 8'd180;
            vga_g_n = 8'd180;
            vga_b_n = 8'd180;
        end
        // blocks
        else begin
            vga_r_n = r_dec;
            vga_g_n = g_dec;
            vga_b_n = b_dec;
        end
    end
    // score
    else if ((x >= 10'd120) && (x < 10'd210) && (y >= 10'd40) && (y < 10'd110)) begin
        vga_g_n = 8'd50;
        vga_b_n = 8'd50;
        // boundary
        if (x == 10'd150 || x == 10'd180) begin
            vga_r_n = 8'd50;
        end
        // first bit
        // corner
        else if (x>=10'd180 && x<10'd188 && y>=10'd40 && y<10'd50) begin
            vga_r_n = (score_7_hex[0] || score_7_hex[5]) ? 8'd255 : 8'd50;
        end
        else if (x>=10'd202 && x<10'd210 && y>=10'd40 && y<10'd50) begin
            vga_r_n = (score_7_hex[0] || score_7_hex[1]) ? 8'd255 : 8'd50;
        end
        else if (x>=10'd180 && x<10'd188 && y>=10'd70 && y<10'd80) begin
            vga_r_n = (score_7_hex[4] || score_7_hex[5] || score_7_hex[6]) ? 8'd255 : 8'd50;
        end
        else if (x>=10'd202 && x<10'd210 && y>=10'd70 && y<10'd80) begin
            vga_r_n = (score_7_hex[1] || score_7_hex[2] || score_7_hex[6]) ? 8'd255 : 8'd50;
        end
        else if (x>=10'd180 && x<10'd188 && y>=10'd100 && y<10'd110) begin
            vga_r_n = (score_7_hex[3] || score_7_hex[4]) ? 8'd255 : 8'd50;
        end
        else if (x>=10'd202 && x<10'd210 && y>=10'd100 && y<10'd110) begin
            vga_r_n = (score_7_hex[2] || score_7_hex[3]) ? 8'd255 : 8'd50;
        end
        // edge
        else if (x >= 10'd180 && x<10'd210 && y >= 10'd40 && y<10'd50) begin
            vga_r_n = score_7_hex[0] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd202 && x<10'd210 && y>=10'd50 && y<10'd70) begin
            vga_r_n = score_7_hex[1] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd202 && x<10'd210 && y>=10'd80 && y<10'd100) begin
            vga_r_n = score_7_hex[2] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd180 && x<10'd210 && y>=10'd100 && y<10'd110) begin
            vga_r_n = score_7_hex[3] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd180 && x<10'd188 && y>=10'd80 && y<10'd100) begin
            vga_r_n = score_7_hex[4] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd180 && x<10'd188 && y>=10'd50 && y<10'd70) begin
            vga_r_n = score_7_hex[5] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd180 && x<10'd210 && y>=10'd70 && y<10'd80) begin
            vga_r_n = score_7_hex[6] ? 8'd255 : 8'd50;
        end
        // second bit
        // corner
        else if (x>=10'd150 && x<10'd158 && y>=10'd40 && y<10'd50) begin
            vga_r_n = (score_7_hex[7] || score_7_hex[12]) ? 8'd255 : 8'd50;
        end
        else if (x>=10'd172 && x<10'd180 && y>=10'd40 && y<10'd50) begin
            vga_r_n = (score_7_hex[7] || score_7_hex[8]) ? 8'd255 : 8'd50;
        end
        else if (x>=10'd150 && x<10'd158 && y>=10'd70 && y<10'd80) begin
            vga_r_n = (score_7_hex[11] || score_7_hex[12] || score_7_hex[13]) ? 8'd255 : 8'd50;
        end
        else if (x>=10'd172 && x<10'd180 && y>=10'd70 && y<10'd80) begin
            vga_r_n = (score_7_hex[8] || score_7_hex[9] || score_7_hex[13]) ? 8'd255 : 8'd50;
        end
        else if (x>=10'd150 && x<10'd158 && y>=10'd100 && y<10'd110) begin
            vga_r_n = (score_7_hex[10] || score_7_hex[11]) ? 8'd255 : 8'd50;
        end
        else if (x>=10'd172 && x<10'd180 && y>=10'd100 && y<10'd110) begin
            vga_r_n = (score_7_hex[9] || score_7_hex[10]) ? 8'd255 : 8'd50;
        end
        // edge
        else if (x >= 10'd150 && x<10'd180 && y >= 10'd40 && y<10'd50) begin
            vga_r_n = score_7_hex[7] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd172 && x<10'd180 && y>=10'd50 && y<10'd70) begin
            vga_r_n = score_7_hex[8] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd172 && x<10'd180 && y>=10'd80 && y<10'd100) begin
            vga_r_n = score_7_hex[9] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd150 && x<10'd180 && y>=10'd100 && y<10'd110) begin
            vga_r_n = score_7_hex[10] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd150 && x<10'd158 && y>=10'd80 && y<10'd100) begin
            vga_r_n = score_7_hex[11] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd150 && x<10'd158 && y>=10'd50 && y<10'd70) begin
            vga_r_n = score_7_hex[12] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd150 && x<10'd180 && y>=10'd70 && y<10'd80) begin
            vga_r_n = score_7_hex[13] ? 8'd255 : 8'd50;
        end
        // third bit
        // corner
        else if (x>=10'd120 && x<10'd128 && y>=10'd40 && y<10'd50) begin
            vga_r_n = (score_7_hex[14] || score_7_hex[19]) ? 8'd255 : 8'd50;
        end
        else if (x>=10'd142 && x<10'd150 && y>=10'd40 && y<10'd50) begin
            vga_r_n = (score_7_hex[14] || score_7_hex[15]) ? 8'd255 : 8'd50;
        end
        else if (x>=10'd120 && x<10'd128 && y>=10'd70 && y<10'd80) begin
            vga_r_n = (score_7_hex[18] || score_7_hex[19] || score_7_hex[20]) ? 8'd255 : 8'd50;
        end
        else if (x>=10'd142 && x<10'd150 && y>=10'd70 && y<10'd80) begin
            vga_r_n = (score_7_hex[15] || score_7_hex[16] || score_7_hex[20]) ? 8'd255 : 8'd50;
        end
        else if (x>=10'd120 && x<10'd128 && y>=10'd100 && y<10'd110) begin
            vga_r_n = (score_7_hex[17] || score_7_hex[18]) ? 8'd255 : 8'd50;
        end
        else if (x>=10'd142 && x<10'd150 && y>=10'd100 && y<10'd110) begin
            vga_r_n = (score_7_hex[16] || score_7_hex[17]) ? 8'd255 : 8'd50;
        end
        // edge
        else if (x>=10'd120 && x<10'd150 && y>=10'd40 && y<10'd50) begin
            vga_r_n = score_7_hex[14] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd142 && x<10'd150 && y>=10'd50 && y<10'd70) begin
            vga_r_n = score_7_hex[15] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd142 && x<10'd150 && y>=10'd80 && y<10'd100) begin
            vga_r_n = score_7_hex[16] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd120 && x<10'd150 && y>=10'd100 && y<10'd110) begin
            vga_r_n = score_7_hex[17] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd120 && x<10'd128 && y>=10'd80 && y<10'd100) begin
            vga_r_n = score_7_hex[18] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd120 && x<10'd128 && y>=10'd50 && y<10'd70) begin
            vga_r_n = score_7_hex[19] ? 8'd255 : 8'd50;
        end
        else if (x>=10'd120 && x<10'd150 && y>=10'd70 && y<10'd80) begin
            vga_r_n = score_7_hex[20] ? 8'd255 : 8'd50;
        end
        // background
        else begin
            vga_r_n = 8'd50;
        end
    end
    else begin
        vga_r_n = 8'd50 + attack_bg_color[22:16];
        vga_g_n = 8'd50;
        vga_b_n = 8'd50;
    end
end

// if touch boundary or other blocks
logic right_enable, left_enable;
assign right_enable = (!(x_center == 4'd9 || b1_x == 4'd9 || b2_x == 4'd9 || b3_x == 4'd9)) &&
                      (blocks[x_center+1][y_center] == 3'b0) &&
                      (blocks[b1_x+1][b1_y] == 3'b0) &&
                      (blocks[b2_x+1][b2_y] == 3'b0) &&
                      (blocks[b3_x+1][b3_y] == 3'b0);
assign left_enable  = (!(x_center == 4'd0 || b1_x == 4'd0 || b2_x == 4'd0 || b3_x == 4'd0)) &&
                      (blocks[x_center-1][y_center] == 3'b0) &&
                      (blocks[b1_x-1][b1_y] == 3'b0) &&
                      (blocks[b2_x-1][b2_y] == 3'b0) &&
                      (blocks[b3_x-1][b3_y] == 3'b0);

// Finite state machine
always_comb begin
    // default blocks color
    for (i=0; i<10; i++) begin
        for (j=0; j<20; j++) begin
            blocks_nxt[i][j] = blocks[i][j];
        end
    end
    state_nxt = state;
    counter_update_nxt = (i_key == speed) ? (counter_update + 5) : (counter_update + 1);
    counter_stall_nxt = 22'd0;
    counter_delete_nxt = counter_delete;
    shape_list_nxt = shape_list;
    shape_nxt = shape;
    shape_hold_nxt = shape_hold;
    counter_shape_nxt = counter_shape; 
    dirc_nxt = dirc;
    score_nxt = score;
    delete_count_nxt = delete_count;
    o_delete_nxt = 3'b0;
    o_finish_nxt = 1'b0;
    x_center_nxt = x_center;
    y_center_nxt = y_center;
    y_low_nxt = y_low;
    //
    case(state)
        S_IDLE: begin
            if (i_start == 1'b1) begin
                state_nxt = S_STAL;
                for (i=0; i<10; i++) begin
                    for (j=0; j<20; j++) begin
                        blocks_nxt[i][j] = 3'b0;
                    end
                end
                counter_update_nxt = 24'b0;
                counter_stall_nxt = 22'b0;
                counter_delete_nxt = 5'b0;
                shape_list_nxt = shape_list;
                shape_hold_nxt = 3'd7;
                counter_shape_nxt = 3'b0;
                dirc_nxt = 2'b0;
                score_nxt = 10'b0;
                delete_count_nxt = 3'b0;
                o_delete_nxt = 3'b0;
                x_center_nxt = 4'd4;
                y_center_nxt = 5'd0;
                y_low_nxt = 5'd0;
            end
            else begin
                for (i=0; i<10; i++) begin
                    for (j=0; j<20; j++) begin
                        blocks_nxt[i][j] = blocks[i][j];
                    end
                end
                state_nxt = S_IDLE;
            end
        end
        S_WAIT: begin
            for (i=0; i<10; i++) begin
                for (j=0; j<20; j++) begin
                    blocks_nxt[i][j] = blocks[i][j];
                end
            end
            counter_stall_nxt = 22'b0;
            y_center_nxt = y_center;
            if (attack_count != 3'b0) begin
                x_center_nxt = x_center;
                state_nxt = S_ATTK;
                y_low_nxt = y_center;
            end
            else begin
                case(i_key)
                    up: begin
                        x_center_nxt = x_center;
                        dirc_nxt = dirc + 1;
                        state_nxt = S_EVAL;
                        y_low_nxt = y_center;
                    end
                    down: begin
                        x_center_nxt = x_center;
                        y_center_nxt = y_low;
                        state_nxt = S_END;
                    end
                    right: begin
                        if (right_enable) begin
                            x_center_nxt = x_center + 1'b1;
                            state_nxt = S_STAL;
                            counter_stall_nxt = 22'b0;
                            y_low_nxt = y_center;
                        end
                        else begin
                            x_center_nxt = x_center;
                            state_nxt = S_WAIT;
                        end
                    end
                    left: begin
                        if (left_enable) begin
                            x_center_nxt = x_center - 1'b1;
                            state_nxt = S_STAL;
                            counter_stall_nxt = 22'b0;
                            y_low_nxt = y_center;
                        end
                        else begin
                            x_center_nxt = x_center;
                            state_nxt = S_WAIT;
                        end
                    end
                    hold: begin
                        // new shape
                        if (shape_hold == 3'd7) begin
                            state_nxt = S_STAL;
                            shape_hold_nxt = shape;
                            if (counter_shape == 3'd6) begin
                                counter_shape_nxt = 3'd0;
                                shape_list_nxt = {shape_list[11:9], shape_list[5:3], shape_list[8:6],
                                                shape_list[20:18], shape_list[2:0], shape_list[14:12],shape_list[17:15]};
                                shape_nxt = shape_list[11:9];
                            end
                            else begin
                                counter_shape_nxt = counter_shape + 1;
                                shape_list_nxt = {shape_list[17:0], shape_list[20:18]};
                                shape_nxt = shape_list[17:15];
                            end
                            dirc_nxt = 2'b0;
                            x_center_nxt = 4'd4;
                            y_center_nxt = 5'b0;
                            y_low_nxt = 5'b0;
                        end
                        else begin
                            // use hold shape
                            state_nxt = S_STAL;
                            shape_nxt = shape_hold;
                            shape_hold_nxt = shape;
                            dirc_nxt = 2'b0;
                            x_center_nxt = 4'd4;
                            y_center_nxt = 5'b0;
                            y_low_nxt = 5'b0;
                        end
                    end
                    default: begin
                        x_center_nxt = x_center;
                        state_nxt = (counter_update >= {1'b0, ~24'b0}) ? S_END : S_WAIT;
                    end
                endcase
            end
        end
        S_EVAL: begin
            for (i=0; i<10; i++) begin
                for (j=0; j<20; j++) begin
                    blocks_nxt[i][j] = blocks[i][j];
                end
            end
            if ((blocks[x_center][y_center] != 3'b0) ||
                (blocks[b1_x][b1_y] != 3'b0) || (blocks[b2_x][b2_y] != 3'b0) || (blocks[b3_x][b3_y] != 3'b0)) begin
                dirc_nxt = dirc - 1;
            end
            else if ((x_center > 4'd9) || (b1_x > 4'd9) || (b2_x > 4'd9) || (b3_x > 4'd9) ||
                     (y_center > 5'd19) || (b1_y > 5'd19) || (b2_y > 5'd19) || (b3_y > 5'd19)) begin
                dirc_nxt = dirc - 1;
            end
            else begin
                dirc_nxt = dirc;
            end
            state_nxt = S_STAL;
            counter_stall_nxt = 22'b0;
            // reset the lowest to current position
        end
        S_STAL: begin
            for (i=0; i<10; i++) begin
                for (j=0; j<20; j++) begin
                    blocks_nxt[i][j] = blocks[i][j];
                end
            end
            counter_stall_nxt = counter_stall + 1;
            // calculate the lowest position
            y_low_nxt = (down_valid) ? (y_low + 1) : y_low;
            // stall time
            if (counter_stall == ~22'b0) begin
                if (y_low == 5'd0) begin
                    state_nxt = S_IDLE;
                    o_finish_nxt = 1'b1;
                end
                else begin
                    state_nxt = (counter_update >= {1'b0, ~24'b0}) ? S_END : S_WAIT;
                    o_finish_nxt = 1'b0;
                end
            end
            else begin
                state_nxt = state;
            end
        end
        S_END: begin
            // falling
            for (i=0; i<10; i++) begin
                for (j=0; j<20; j++) begin
                    blocks_nxt[i][j] = blocks[i][j];
                end
            end
            if (y_center == y_low) begin
                state_nxt = S_DELE;
                delete_count_nxt = 3'b0;
                blocks_nxt[x_center][y_center] = shape+1;
                blocks_nxt[b1_x][b1_y] = shape+1;
                blocks_nxt[b2_x][b2_y] = shape+1;
                blocks_nxt[b3_x][b3_y] = shape+1;
            end
            else begin
                state_nxt = S_WAIT;
                y_center_nxt = y_center + 1;
                y_low_nxt = y_low;
            end
            counter_update_nxt = 25'b0;
            counter_stall_nxt = 22'b0;
            counter_delete_nxt = 5'd0;
        end
        S_DELE: begin
            for (i=0; i<10; i++) begin
                for (j=0; j<20; j++) begin
                    blocks_nxt[i][j] = blocks[i][j];
                end
            end
            if (counter_delete == 5'd19) begin
                // deletion
                state_nxt = S_STAL;
                counter_delete_nxt = 5'd0;
                delete_count_nxt = delete_count;
                o_delete_nxt = delete_count;
                if((blocks[0][counter_delete] != 0) && (blocks[1][counter_delete] != 0) &&
                   (blocks[2][counter_delete] != 0) && (blocks[3][counter_delete] != 0) &&
                   (blocks[4][counter_delete] != 0) && (blocks[5][counter_delete] != 0) && 
                   (blocks[6][counter_delete] != 0) && (blocks[7][counter_delete] != 0) &&
                   (blocks[8][counter_delete] != 0) && (blocks[9][counter_delete] != 0)) begin
                    delete_count_nxt = delete_count + 1;
                    o_delete_nxt = delete_count + 1;
                    for (i=0; i<10; i++) begin
                        for (j=0; j<20; j++) begin
                            if (j == 0) blocks_nxt[i][j] = 3'b0;
                            else blocks_nxt[i][j] = blocks[i][j-1];
                        end
                    end
                end
                // score update
                score_nxt = (delete_count_nxt == 3'd4) ? (score + 10'd7) :
                            (delete_count_nxt == 3'd3) ? (score + 10'd5) :
                            (delete_count_nxt == 3'd2) ? (score + 10'd3) :
                            (delete_count_nxt == 3'd1) ? (score + 10'd1) : score;
                // new shape
                if (counter_shape == 3'd6) begin
                    counter_shape_nxt = 3'd0;
                    shape_list_nxt = {shape_list[11:9], shape_list[5:3], shape_list[8:6],
                                      shape_list[20:18], shape_list[2:0], shape_list[14:12],shape_list[17:15]};
                    shape_nxt = shape_list[11:9];
                end
                else begin
                    counter_shape_nxt = counter_shape + 1;
                    shape_list_nxt = {shape_list[17:0], shape_list[20:18]};
                    shape_nxt = shape_list[17:15];
                end
                dirc_nxt = 2'b0;
                x_center_nxt = 4'd4;
                y_center_nxt = 5'b0;
                y_low_nxt = 5'b0;
            end
            else begin
                // deletion
                state_nxt = S_DELE;
                counter_delete_nxt = counter_delete + 1;
                delete_count_nxt = delete_count;
                if((blocks[0][counter_delete] != 0) && (blocks[1][counter_delete] != 0) &&
                   (blocks[2][counter_delete] != 0) && (blocks[3][counter_delete] != 0) &&
                   (blocks[4][counter_delete] != 0) && (blocks[5][counter_delete] != 0) && 
                   (blocks[6][counter_delete] != 0) && (blocks[7][counter_delete] != 0) &&
                   (blocks[8][counter_delete] != 0) && (blocks[9][counter_delete] != 0)) begin
                    delete_count_nxt = delete_count + 1;
                    for (i=0; i<10; i++) begin
                        for (j=0; j<20; j++) begin
                            if (j == 0) blocks_nxt[i][j] = 3'b0;
                            else if (j <= counter_delete) blocks_nxt[i][j] = blocks[i][j-1];
                            else blocks_nxt[i][j] = blocks[i][j];
                        end
                    end
                end
            end
        end
        S_ATTK: begin
            for (i=0; i<10; i++) begin
                for (j=0; j<20; j++) begin
                    blocks_nxt[i][j] = blocks[i][j];
                end
            end
            if (attack_count == 3'd0) begin
                state_nxt = S_STAL;
            end
            else begin
                state_nxt = S_ATTK;
                // move moving shape
                if ((y_center!=0) && (b1_y!=0) && (b2_y!=0) && (b3_y!=0)) begin
                    y_center_nxt = y_center-1;
                    y_low_nxt = y_center-1;
                end
                else begin
                    y_center_nxt = y_center;
                    y_low_nxt = y_center;
                end
                // add garbage row
                for (i=0; i<10; i++) begin
                    for (j=0; j<19; j++) begin
                        blocks_nxt[i][j] = blocks[i][j+1];
                    end
                end
                for (i=0; i<10; i++) begin
                    blocks_nxt[i][19] = rand_attk[i] ? 3'd4 : 3'd0;
                end
            end
        end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        for (i=0; i<10; i++) begin
            for (j=0; j<20; j++) begin
                blocks[i][j] <= 3'd0;
            end
        end
        state <= S_IDLE;
        counter_update <= 25'b0;
        counter_stall <= 22'b0;
        counter_delete <= 5'b0;
        shape_list <= {3'd0, 3'd1, 3'd2, 3'd3, 3'd4, 3'd5, 3'd6};
        shape <= 3'd0;
        shape_hold <= 3'd7;
        counter_shape <= 3'b0;
        dirc <= 2'b0;
        score <= 10'b0;
        delete_count <= 3'b0;
        o_delete <= 3'b0;
        o_finish <= 1'b0;
        x_center <= 4'd4;
        y_center <= 5'd0;
        y_low <= 5'd0;
        attack_count <= 3'd0;
        rand_attk <= 10'b1111111101;
        attack_bg_color <= 23'b0;
        vga_r <= 8'b0;
        vga_g <= 8'b0;
        vga_b <= 8'b0;
    end
    else begin
        for (i=0; i<10; i++) begin
            for (j=0; j<20; j++) begin
                blocks[i][j] <= blocks_nxt[i][j];
            end
        end
        state <= (i_stop) ? S_IDLE : state_nxt;
        counter_update <= counter_update_nxt;
        counter_stall <= counter_stall_nxt;
        counter_delete <= counter_delete_nxt;
        shape_list <= shape_list_nxt;
        shape <= shape_nxt;
        shape_hold <= shape_hold_nxt;
        counter_shape <= counter_shape_nxt;
        dirc <= dirc_nxt;
        score <= score_nxt;
        delete_count <= delete_count_nxt;
        o_delete <= o_delete_nxt;
        o_finish <= o_finish_nxt;
        x_center <= x_center_nxt;
        y_center <= y_center_nxt;
        y_low <= y_low_nxt;
        attack_count <= attack_count_nxt;
        rand_attk <= rand_attk_nxt;
        attack_bg_color <= attack_bg_color_nxt;
        vga_r <= vga_r_n;
        vga_g <= vga_g_n;
        vga_b <= vga_b_n;
    end
end
endmodule