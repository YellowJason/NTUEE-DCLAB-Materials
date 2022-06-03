module Game(
    input i_clk,
    input i_rst_n,
    input i_start,
    input [9:0] x,
    input [9:0] y,
    input [7:0] i_key,
    output [7:0] o_vga_r,
    output [7:0] o_vga_g,
    output [7:0] o_vga_b,
    output [7:0] o_score
);

integer i;
integer j;

// states
parameter S_WAIT = 3'b000; // Wait key action
parameter S_EVAL = 3'b001; // evaluate if the key is workable
parameter S_STAL = 3'b010; // stall a little time after update
parameter S_END  = 3'b011; // evaluate if the block reach bottom
parameter S_DELE = 3'b100; // delete full rows
parameter S_IDLE = 3'b101; // state before start
logic [2:0] state, state_nxt;

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
assign o_score = score[7:0];
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

// hold shape
logic [2:0] shape_hold, shape_hold_nxt;

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
hold_text = (x==9'd138 && y>=9'd130 && y<9'd150) || (x>=9'd138 && x<9'd210 && y==9'd140) || (x==9'd156 && y>=9'd130 && y<9'd150) //H
          ||(x==9'd156 && y>=9'd130 && y<9'd150) || (x>=9'd156 && x<9'd174 && y==9'd130) || (x>=9'd156 && x<9'd174 && y==9'd150) || (x==9'd174 && y>=9'd130 && y<9'd150) //O
          ||(x==9'd174 && y>=9'd130 && y<9'd150) || (x>=9'd176 && x<9'd192 && y==9'd150) //L
          ||(x==9'd192 && y>=9'd130 && y<9'd150) || (x>=9'd192 && x<9'd210 && y==5*(x-192)/18+130) || (x>=9'd192 && x<9'd210 && y==-5*(x-192)/18+150) || (x==9'd210 && y>=9'd135 && y<9'd145); //D

// showing
always_comb begin
    // hold text boundary
    if ((x==9'd156 || x==9'd174 || x==9'd192) && (y>=9'd130 && y<9'd150)) begin
        vga_r_n = 8'd50;
        vga_g_n = 8'd50;
        vga_b_n = 8'd50;
    end
    else if (hold_text) begin
        vga_r_n = 8'd255;
        vga_g_n = 8'd255;
        vga_b_n = 8'd255;
    end
    else if ((x >= 9'd138) && (x <= 9'd210) && (y >= 9'd160) && (y <= 9'd240)) begin
        // hold block boundary
        if (((x-138)%18 == 0) || ((y-160)%20 == 0)) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else begin
            vga_r_n = 8'd50;
            vga_g_n = 8'd50;
            vga_b_n = 8'd50;
        end
    end
    else if ((x >= 9'd230) && (x <= 9'd410) && (y >= 9'd40) && (y <= 9'd440)) begin
        // block boundary
        if (((x-230)%18 == 0) || ((y-40)%20 == 0)) begin
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
    else if ((x >= 9'd120) && (x < 9'd210) && (y >= 9'd40) && (y < 9'd110)) begin
        vga_g_n = 8'd50;
        vga_b_n = 8'd50;
        // boundary
        if (x == 9'd150 || x == 9'd180) begin
            vga_r_n = 8'd50;
        end
        // first bit
        // corner
        else if (x>=9'd180 && x<9'd188 && y>=9'd40 && y<9'd50) begin
            vga_r_n = (score_7_hex[0] || score_7_hex[5]) ? 8'd255 : 8'd50;
        end
        else if (x>=9'd202 && x<9'd210 && y>=9'd40 && y<9'd50) begin
            vga_r_n = (score_7_hex[0] || score_7_hex[1]) ? 8'd255 : 8'd50;
        end
        else if (x>=9'd180 && x<9'd188 && y>=9'd70 && y<9'd80) begin
            vga_r_n = (score_7_hex[4] || score_7_hex[5] || score_7_hex[6]) ? 8'd255 : 8'd50;
        end
        else if (x>=9'd202 && x<9'd210 && y>=9'd70 && y<9'd80) begin
            vga_r_n = (score_7_hex[1] || score_7_hex[2] || score_7_hex[6]) ? 8'd255 : 8'd50;
        end
        else if (x>=9'd180 && x<9'd188 && y>=9'd100 && y<9'd110) begin
            vga_r_n = (score_7_hex[3] || score_7_hex[4]) ? 8'd255 : 8'd50;
        end
        else if (x>=9'd202 && x<9'd210 && y>=9'd100 && y<9'd110) begin
            vga_r_n = (score_7_hex[2] || score_7_hex[3]) ? 8'd255 : 8'd50;
        end
        // edge
        else if (x >= 9'd180 && x<9'd210 && y >= 9'd40 && y<9'd50) begin
            vga_r_n = score_7_hex[0] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd202 && x<9'd210 && y>=9'd50 && y<9'd70) begin
            vga_r_n = score_7_hex[1] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd202 && x<9'd210 && y>=9'd80 && y<9'd100) begin
            vga_r_n = score_7_hex[2] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd180 && x<9'd210 && y>=9'd100 && y<9'd110) begin
            vga_r_n = score_7_hex[3] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd180 && x<9'd188 && y>=9'd80 && y<9'd100) begin
            vga_r_n = score_7_hex[4] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd180 && x<9'd188 && y>=9'd50 && y<9'd70) begin
            vga_r_n = score_7_hex[5] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd180 && x<9'd210 && y>=9'd70 && y<9'd80) begin
            vga_r_n = score_7_hex[6] ? 8'd255 : 8'd50;
        end
        // second bit
        // corner
        else if (x>=9'd150 && x<9'd158 && y>=9'd40 && y<9'd50) begin
            vga_r_n = (score_7_hex[7] || score_7_hex[12]) ? 8'd255 : 8'd50;
        end
        else if (x>=9'd172 && x<9'd180 && y>=9'd40 && y<9'd50) begin
            vga_r_n = (score_7_hex[7] || score_7_hex[8]) ? 8'd255 : 8'd50;
        end
        else if (x>=9'd150 && x<9'd158 && y>=9'd70 && y<9'd80) begin
            vga_r_n = (score_7_hex[11] || score_7_hex[12] || score_7_hex[13]) ? 8'd255 : 8'd50;
        end
        else if (x>=9'd172 && x<9'd180 && y>=9'd70 && y<9'd80) begin
            vga_r_n = (score_7_hex[8] || score_7_hex[9] || score_7_hex[13]) ? 8'd255 : 8'd50;
        end
        else if (x>=9'd150 && x<9'd158 && y>=9'd100 && y<9'd110) begin
            vga_r_n = (score_7_hex[10] || score_7_hex[11]) ? 8'd255 : 8'd50;
        end
        else if (x>=9'd172 && x<9'd180 && y>=9'd100 && y<9'd110) begin
            vga_r_n = (score_7_hex[9] || score_7_hex[10]) ? 8'd255 : 8'd50;
        end
        // edge
        else if (x >= 9'd150 && x<9'd180 && y >= 9'd40 && y<9'd50) begin
            vga_r_n = score_7_hex[7] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd172 && x<9'd180 && y>=9'd50 && y<9'd70) begin
            vga_r_n = score_7_hex[8] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd172 && x<9'd180 && y>=9'd80 && y<9'd100) begin
            vga_r_n = score_7_hex[9] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd150 && x<9'd180 && y>=9'd100 && y<9'd110) begin
            vga_r_n = score_7_hex[10] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd150 && x<9'd158 && y>=9'd80 && y<9'd100) begin
            vga_r_n = score_7_hex[11] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd150 && x<9'd158 && y>=9'd50 && y<9'd70) begin
            vga_r_n = score_7_hex[12] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd150 && x<9'd180 && y>=9'd70 && y<9'd80) begin
            vga_r_n = score_7_hex[13] ? 8'd255 : 8'd50;
        end
        // third bit
        // corner
        else if (x>=9'd120 && x<9'd128 && y>=9'd40 && y<9'd50) begin
            vga_r_n = (score_7_hex[14] || score_7_hex[19]) ? 8'd255 : 8'd50;
        end
        else if (x>=9'd142 && x<9'd150 && y>=9'd40 && y<9'd50) begin
            vga_r_n = (score_7_hex[14] || score_7_hex[15]) ? 8'd255 : 8'd50;
        end
        else if (x>=9'd120 && x<9'd128 && y>=9'd70 && y<9'd80) begin
            vga_r_n = (score_7_hex[18] || score_7_hex[19] || score_7_hex[20]) ? 8'd255 : 8'd50;
        end
        else if (x>=9'd142 && x<9'd150 && y>=9'd70 && y<9'd80) begin
            vga_r_n = (score_7_hex[15] || score_7_hex[16] || score_7_hex[20]) ? 8'd255 : 8'd50;
        end
        else if (x>=9'd120 && x<9'd128 && y>=9'd100 && y<9'd110) begin
            vga_r_n = (score_7_hex[17] || score_7_hex[18]) ? 8'd255 : 8'd50;
        end
        else if (x>=9'd142 && x<9'd150 && y>=9'd100 && y<9'd110) begin
            vga_r_n = (score_7_hex[16] || score_7_hex[17]) ? 8'd255 : 8'd50;
        end
        // edge
        else if (x>=9'd120 && x<9'd150 && y>=9'd40 && y<9'd50) begin
            vga_r_n = score_7_hex[14] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd142 && x<9'd150 && y>=9'd50 && y<9'd70) begin
            vga_r_n = score_7_hex[15] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd142 && x<9'd150 && y>=9'd80 && y<9'd100) begin
            vga_r_n = score_7_hex[16] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd120 && x<9'd150 && y>=9'd100 && y<9'd110) begin
            vga_r_n = score_7_hex[17] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd120 && x<9'd128 && y>=9'd80 && y<9'd100) begin
            vga_r_n = score_7_hex[18] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd120 && x<9'd128 && y>=9'd50 && y<9'd70) begin
            vga_r_n = score_7_hex[19] ? 8'd255 : 8'd50;
        end
        else if (x>=9'd120 && x<9'd150 && y>=9'd70 && y<9'd80) begin
            vga_r_n = score_7_hex[20] ? 8'd255 : 8'd50;
        end
        // background
        else begin
            vga_r_n = 8'd50;
        end
    end
    else begin
        vga_r_n = 8'd50;
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
    counter_delete_nxt = 5'b0;
    shape_list_nxt = shape_list;
    shape_nxt = shape;
    shape_hold_nxt = shape_hold;
    counter_shape_nxt = counter_shape; 
    dirc_nxt = dirc;
    score_nxt = score;
    delete_count_nxt = delete_count;
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
                counter_shape_nxt = 3'b0;
                dirc_nxt = 2'b0;
                score_nxt = 10'b0;
                delete_count_nxt = 3'b0;
                x_center_nxt = 4'd4;
                y_center_nxt = 5'd0;
                y_low_nxt = 5'd0;
            end
            else begin
                state_nxt = S_IDLE;
            end
        end
        S_WAIT: begin
            counter_stall_nxt = 22'b0;
            y_center_nxt = y_center;
            y_low_nxt = y_low;
            case(i_key)
                up: begin
                    x_center_nxt = x_center;
                    dirc_nxt = dirc + 1;
                    state_nxt = S_EVAL;
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
        S_EVAL: begin
            if (i_key == up) begin
                if ((blocks[x_center][y_center] != 3'b0) ||
                    (blocks[b1_x][b1_y] != 3'b0) || (blocks[b2_x][b2_y] != 3'b0) || (blocks[b3_x][b3_y] != 3'b0) ||
                    (x_center > 4'd9) || (b1_x > 4'd9) || (b2_x > 4'd9) || (b3_x > 4'd9) ||
                    (y_center > 5'd19) || (b1_y > 5'd19) || (b2_y > 5'd19) || (b3_y > 5'd19)) begin
                    dirc_nxt = dirc - 1;
                end
                else begin
                    dirc_nxt = dirc;
                end
            end
            state_nxt = S_STAL;
            counter_stall_nxt = 22'b0;
            x_center_nxt = x_center;
            y_center_nxt = y_center;
            // reset the lowest to current position
            y_low_nxt = y_center;
        end
        S_STAL: begin
            counter_stall_nxt = counter_stall + 1;
            x_center_nxt = x_center;
            y_center_nxt = y_center;
            // calculate the lowest position
            y_low_nxt = (down_valid) ? (y_low + 1) : y_low;
            // stall time
            if (counter_stall == ~22'b0) begin
                if (y_low == 5'd0) state_nxt = S_IDLE;
                else               state_nxt = (counter_update >= {1'b0, ~24'b0}) ? S_END : S_WAIT;
            end
            else begin
                state_nxt = state;
            end
        end
        S_END: begin
            // falling
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
                x_center_nxt = x_center;
                y_center_nxt = y_center + 1;
                y_low_nxt = y_low;
            end
            counter_update_nxt = 25'b0;
            counter_stall_nxt = 22'b0;
        end
        S_DELE: begin
            if (counter_delete == 5'd19) begin
                // deletion
                state_nxt = S_STAL;
                counter_delete_nxt = 5'd0;
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
        default: begin
            for (i=0; i<10; i++) begin
                for (j=0; j<20; j++) begin
                    blocks_nxt[i][j] = blocks[i][j];
                end
            end
            counter_update_nxt = counter_update + 1;
            state_nxt = state;
            counter_stall_nxt = counter_stall;
            shape_list_nxt = shape_list;
            counter_shape_nxt = counter_shape;
            dirc_nxt = dirc;
            score_nxt = score;
            delete_count_nxt = delete_count;
            x_center_nxt = x_center;
            y_center_nxt = y_center;
            y_low_nxt = y_low;
        end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        for (i=0; i<20; i++) begin
            blocks[0][i] <= 3'd0;
            blocks[1][i] <= 3'd0;
            blocks[2][i] <= 3'd0;
            blocks[3][i] <= 3'd0;
            blocks[4][i] <= 3'd0;
            blocks[5][i] <= 3'd0;
            blocks[6][i] <= 3'd0;
            blocks[7][i] <= 3'd0;
            blocks[8][i] <= 3'd0;
            blocks[9][i] <= 3'd0;
        end
        state <= S_IDLE;
        counter_update <= 24'b0;
        counter_stall <= 22'b0;
        counter_delete <= 5'b0;
        shape_list <= {3'd0, 3'd1, 3'd2, 3'd3, 3'd4, 3'd5, 3'd6};
        shape <= 3'd0;
        shape_hold <= 3'd7;
        counter_shape <= 3'b0;
        dirc <= 2'b0;
        score <= 10'b0;
        delete_count <= 3'b0;
        x_center <= 4'd4;
        y_center <= 5'd0;
        y_low <= 5'd0;
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
        state <= state_nxt;
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
        x_center <= x_center_nxt;
        y_center <= y_center_nxt;
        y_low <= y_low_nxt;
        vga_r <= vga_r_n;
        vga_g <= vga_g_n;
        vga_b <= vga_b_n;
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