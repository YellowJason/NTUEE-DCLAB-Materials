module Top(
    input i_clk,
    input i_rst_n,
    input [9:0] x,
    input [9:0] y,
    input [7:0] i_key_1,
    input [7:0] i_key_2,
    output logic [7:0] o_vga_r,
    output logic [7:0] o_vga_g,
    output logic [7:0] o_vga_b
);

parameter up = 8'h75;
parameter down = 8'h72;
parameter enter = 8'h5a;
parameter esc = 8'h76;

// states
parameter S_IDLE = 2'b00;
parameter S_1P = 2'b01;
parameter S_2P = 2'b10;
logic [1:0] state, state_nxt;

// mode 0:single, 1:double
logic mode, mode_nxt;

// x coordinate for game 1 & 2
logic [8:0] x_game_1, x_game_2;
assign x_game_1 = (state == S_1P) ? x : (x - 9'd215);
assign x_game_2 = x + 9'd105;

// control signal
logic start, start_nxt;

// 2 game module
logic [7:0] r_1, g_1, b_1, r_2, g_2, b_2;
Game game0(
	.i_clk(i_clk),
    .i_rst_n(i_rst_n),
	.i_start(start),
    .x(x_game_1),
    .y(y),
	.i_key(i_key_1),
    .o_vga_r(r_1),
	.o_vga_g(g_1),
	.o_vga_b(b_1),
);
Game_2 game1(
	.i_clk(i_clk),
    .i_rst_n(i_rst_n),
	.i_start(start),
    .x(x_game_2),
    .y(y),
	.i_key(i_key_2),
    .o_vga_r(r_2),
	.o_vga_g(g_2),
	.o_vga_b(b_2),
);

// vga_signal
logic [7:0] vga_r, vga_r_n, vga_g, vga_g_n, vga_b, vga_b_n;
always_comb begin
    if (state == S_1P) begin
        if (x > 9'd110 && x< 9'd420) begin
            o_vga_r = r_1;
            o_vga_g = g_1;
            o_vga_b = b_1;
        end
        else begin
            o_vga_r = 8'd50;
            o_vga_g = 8'd50;
            o_vga_b = 8'd50;
        end
    end
    else if (state == S_2P) begin
        if (x > 9'd320) begin
            o_vga_r = r_1;
            o_vga_g = g_1;
            o_vga_b = b_1;
        end
        else begin
            o_vga_r = r_2;
            o_vga_g = g_2;
            o_vga_b = b_2;
        end
    end
    else begin
        o_vga_r = vga_r;
        o_vga_g = vga_g;
        o_vga_b = vga_b;
    end
end

// text of TETRIS
logic text_T1, text_E, text_T2, text_R, text_I, text_S;
assign text_T1 = (x>=9'd55 && x<=9'd135 && y>=9'd80 && y<=9'd100) || (x>=9'd85 && x<=9'd105 && y>=9'd100 && y<=9'd180);
assign text_E  = (x>=9'd145 && x<=9'd165 && y>=9'd80 && y<=9'd180) || (x>=9'd165 && x<=9'd225 && y>=9'd80 && y<=9'd100)
               ||(x>=9'd165 && x<=9'd225 && y>=9'd120 && y<=9'd140) || (x>=9'd165 && x<=9'd225 && y>=9'd160 && y<=9'd180);
assign text_T2 = (x>=9'd235 && x<=9'd315 && y>=9'd80 && y<=9'd100) || (x>=9'd265 && x<=9'd285 && y>=9'd100 && y<=9'd180);
assign text_R  = (x>=9'd325 && x<=9'd345 && y>=9'd80 && y<=9'd180) || (x>=9'd345 && x<=9'd385 && y>=9'd80 && y<=9'd100)
               ||(x>=9'd385 && x<=9'd405 && y>=9'd100 && y<=9'd120) || (x>=9'd345 && x<=9'd385 && y>=9'd120 && y<=9'd140)
               ||(x>=9'd365 && x<=9'd385 && y>=9'd140 && y<=9'd160) || (x>=9'd385 && x<=9'd405 && y>=9'd160 && y<=9'd180);
assign text_I  = (x>=9'd425 && x<=9'd485 && y>=9'd80 && y<=9'd100) || (x>=9'd445 && x<=9'd465 && y>=9'd100 && y<=9'd160)
               ||(x>=9'd415 && x<=9'd495 && y>=9'd160 && y<=9'd180);
assign text_S  = (x>=9'd525 && x<=9'd585 && y>=9'd80 && y<=9'd100) || (x>=9'd505 && x<=9'd525 && y>=9'd80 && y<=9'd140)
               ||(x>=9'd525 && x<=9'd585 && y>=9'd120 && y<=9'd140) || (x>=9'd565 && x<=9'd585 && y>=9'd140 && y<=9'd180)
               ||(x>=9'd505 && x<=9'd565 && y>=9'd160 && y<=9'd180);

// text of 1P, 2P, and boundaries
logic text_1P, text_2P, boundary1, boundary2;
assign text_1P = (x>=9'd285 && x<=9'd290 && y>=9'd230 && y<=9'd240) || (x>=9'd290 && x<=9'd300 && y>=9'd230 && y<=9'd280)
               ||(x>=9'd280 && x<=9'd310 && y>=9'd280 && y<=9'd290) || (x>=9'd330 && x<=9'd340 && y>=9'd230 && y<=9'd290)
               ||(x>=9'd340 && x<=9'd350 && y>=9'd230 && y<=9'd240) || (x>=9'd350 && x<=9'd360 && y>=9'd240 && y<=9'd250)
               ||(x>=9'd340 && x<=9'd350 && y>=9'd250 && y<=9'd260);
assign text_2P = (x>=9'd280 && x<=9'd300 && y>=9'd330 && y<=9'd340) || (x>=9'd300 && x<=9'd310 && y>=9'd330 && y<=9'd365)
               ||(x>=9'd280 && x<=9'd300 && y>=9'd355 && y<=9'd365) || (x>=9'd280 && x<=9'd290 && y>=9'd365 && y<=9'd390)
               ||(x>=9'd290 && x<=9'd310 && y>=9'd380 && y<=9'd390) || (x>=9'd330 && x<=9'd340 && y>=9'd330 && y<=9'd390)
               ||(x>=9'd340 && x<=9'd350 && y>=9'd330 && y<=9'd340) || (x>=9'd350 && x<=9'd360 && y>=9'd340 && y<=9'd350)
               ||(x>=9'd340 && x<=9'd350 && y>=9'd350 && y<=9'd360);
assign boundary1 = (x>=9'd255 && x<=9'd260 && y>=9'd220 && y<=9'd300) || (x>=9'd260 && x<=9'd380 && y>=9'd220 && y<=9'd225)
                 ||(x>=9'd380 && x<=9'd385 && y>=9'd220 && y<=9'd300) || (x>=9'd260 && x<=9'd380 && y>=9'd295 && y<=9'd300);
assign boundary2 = (x>=9'd255 && x<=9'd260 && y>=9'd320 && y<=9'd400) || (x>=9'd260 && x<=9'd380 && y>=9'd320 && y<=9'd325)
                 ||(x>=9'd380 && x<=9'd385 && y>=9'd320 && y<=9'd400) || (x>=9'd260 && x<=9'd380 && y>=9'd395 && y<=9'd400);

// home page
always_comb begin
    if (mode == 1'b0) begin
        if (text_T1) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (text_E) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (text_T2) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (text_R) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (text_I) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (text_S) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (text_1P) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (text_2P) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (boundary1) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (boundary2) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd20;
        end
    end
    else begin
        if (text_T1) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (text_E) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (text_T2) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (text_R) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (text_I) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (text_S) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (text_1P) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (text_2P) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (boundary1) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else if (boundary2) begin
            vga_r_n = 8'd255;
            vga_g_n = 8'd255;
            vga_b_n = 8'd255;
        end
        else begin
            vga_r_n = 8'd20;
            vga_g_n = 8'd20;
            vga_b_n = 8'd255;
        end
    end
end

always_comb begin
    // default value
    state_nxt = state;
    mode_nxt = mode;
    start_nxt = start;
    // finite state machine
    case(state)
        S_IDLE: begin
            if (i_key_1 == down)    mode_nxt = 1'b1;
            else if (i_key_1 == up) mode_nxt = 1'b0;
            else                    mode_nxt = mode;

            if (i_key_1 == enter) begin
                start_nxt = 1'b1;
                state_nxt = mode ? S_2P : S_1P;
            end
            else begin
                start_nxt = 1'b0;
                state_nxt = S_IDLE;
            end
        end
        S_1P: begin
            if (i_key_1 == esc) state_nxt = S_IDLE;
            else                state_nxt = state;
            start_nxt = 1'b0;
        end
        S_2P: begin
            if (i_key_1 == esc) state_nxt = S_IDLE;
            else                state_nxt = state;
            start_nxt = 1'b0;
        end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state <= 2'b00;
        mode <= 1'b0;
        start <= 1'b0;
        vga_r <= 8'd0;
        vga_g <= 8'd0;
        vga_b <= 8'd0;
    end
    else begin
        state <= state_nxt;
        mode <= mode_nxt;
        start <= start_nxt;
        vga_r <= vga_r_n;
        vga_g <= vga_g_n;
        vga_b <= vga_b_n;
    end
end

endmodule