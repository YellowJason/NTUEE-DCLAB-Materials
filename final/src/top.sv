module Top(
    input i_clk,
    input i_rst_n,
    input [9:0] x,
    input [9:0] y,
    input [7:0] i_key_1,
    input [7:0] i_key_2,
    output [2:0] state_1,
    output [2:0] state_2,
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
assign x_game_1 = (state == S_1P) ? x : (x - 10'd215);
assign x_game_2 = x + 10'd105;

// control signal
logic start, start_nxt;
logic stop, stop_nxt;

// 2 game module
logic [7:0] r_1, g_1, b_1, r_2, g_2, b_2;
logic [2:0] delete_1, delete_2;
logic finish_1, finish_2;
Game game0(
	.i_clk(i_clk),
    .i_rst_n(i_rst_n),
	.i_start(start),
    .i_stop(stop),
    .x(x_game_1),
    .y(y),
	.i_key(i_key_1),
    .o_state(state_1),
    .o_delete(delete_1),
    .o_finish(finish_1),
    .o_vga_r(r_1),
	.o_vga_g(g_1),
	.o_vga_b(b_1),
);
Game_2 game1(
	.i_clk(i_clk),
    .i_rst_n(i_rst_n),
	.i_start(start),
    .i_stop(stop),
    .x(x_game_2),
    .y(y),
	.i_key(i_key_2),
    .o_state(state_2),
    .o_delete(delete_2),
    .o_finish(finish_2),
    .o_vga_r(r_2),
	.o_vga_g(g_2),
	.o_vga_b(b_2),
);

// vga_signal
logic [7:0] vga_r, vga_r_n, vga_g, vga_g_n, vga_b, vga_b_n;
always_comb begin
    if (state == S_1P) begin
        if (x >= 10'd100 && x < 10'd500) begin
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
        if (x > 10'd320) begin
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
assign text_T1 = (x>=10'd55 && x<=10'd135 && y>=10'd80 && y<=10'd100) || (x>=10'd85 && x<=10'd105 && y>=10'd100 && y<=10'd180);
assign text_E  = (x>=10'd145 && x<=10'd165 && y>=10'd80 && y<=10'd180) || (x>=10'd165 && x<=10'd225 && y>=10'd80 && y<=10'd100)
               ||(x>=10'd165 && x<=10'd225 && y>=10'd120 && y<=10'd140) || (x>=10'd165 && x<=10'd225 && y>=10'd160 && y<=10'd180);
assign text_T2 = (x>=10'd235 && x<=10'd315 && y>=10'd80 && y<=10'd100) || (x>=10'd265 && x<=10'd285 && y>=10'd100 && y<=10'd180);
assign text_R  = (x>=10'd325 && x<=10'd345 && y>=10'd80 && y<=10'd180) || (x>=10'd345 && x<=10'd385 && y>=10'd80 && y<=10'd100)
               ||(x>=10'd385 && x<=10'd405 && y>=10'd100 && y<=10'd120) || (x>=10'd345 && x<=10'd385 && y>=10'd120 && y<=10'd140)
               ||(x>=10'd365 && x<=10'd385 && y>=10'd140 && y<=10'd160) || (x>=10'd385 && x<=10'd405 && y>=10'd160 && y<=10'd180);
assign text_I  = (x>=10'd425 && x<=10'd485 && y>=10'd80 && y<=10'd100) || (x>=10'd445 && x<=10'd465 && y>=10'd100 && y<=10'd160)
               ||(x>=10'd415 && x<=10'd495 && y>=10'd160 && y<=10'd180);
assign text_S  = (x>=10'd525 && x<=10'd585 && y>=10'd80 && y<=10'd100) || (x>=10'd505 && x<=10'd525 && y>=10'd80 && y<=10'd140)
               ||(x>=10'd525 && x<=10'd585 && y>=10'd120 && y<=10'd140) || (x>=10'd565 && x<=10'd585 && y>=10'd140 && y<=10'd180)
               ||(x>=10'd505 && x<=10'd565 && y>=10'd160 && y<=10'd180);

// text of 1P, 2P, and boundaries
logic text_1P, text_2P, boundary1, boundary2;
assign text_1P = (x>=10'd285 && x<=10'd290 && y>=10'd230 && y<=10'd240) || (x>=10'd290 && x<=10'd300 && y>=10'd230 && y<=10'd280)
               ||(x>=10'd280 && x<=10'd310 && y>=10'd280 && y<=10'd290) || (x>=10'd320 && x<=10'd330 && y>=10'd230 && y<=10'd290)
               ||(x>=10'd330 && x<=10'd350 && y>=10'd230 && y<=10'd240) || (x>=10'd350 && x<=10'd360 && y>=10'd240 && y<=10'd260)
               ||(x>=10'd330 && x<=10'd350 && y>=10'd260 && y<=10'd270);
assign text_2P = (x>=10'd280 && x<=10'd300 && y>=10'd330 && y<=10'd340) || (x>=10'd300 && x<=10'd310 && y>=10'd330 && y<=10'd365)
               ||(x>=10'd280 && x<=10'd300 && y>=10'd355 && y<=10'd365) || (x>=10'd280 && x<=10'd290 && y>=10'd365 && y<=10'd390)
               ||(x>=10'd290 && x<=10'd310 && y>=10'd380 && y<=10'd390) || (x>=10'd320 && x<=10'd330 && y>=10'd330 && y<=10'd390)
               ||(x>=10'd330 && x<=10'd350 && y>=10'd330 && y<=10'd340) || (x>=10'd350 && x<=10'd360 && y>=10'd340 && y<=10'd360)
               ||(x>=10'd330 && x<=10'd350 && y>=10'd360 && y<=10'd370);
assign boundary1 = (x>=10'd255 && x<=10'd260 && y>=10'd220 && y<=10'd300) || (x>=10'd260 && x<=10'd380 && y>=10'd220 && y<=10'd225)
                 ||(x>=10'd380 && x<=10'd385 && y>=10'd220 && y<=10'd300) || (x>=10'd260 && x<=10'd380 && y>=10'd295 && y<=10'd300);
assign boundary2 = (x>=10'd255 && x<=10'd260 && y>=10'd320 && y<=10'd400) || (x>=10'd260 && x<=10'd380 && y>=10'd320 && y<=10'd325)
                 ||(x>=10'd380 && x<=10'd385 && y>=10'd320 && y<=10'd400) || (x>=10'd260 && x<=10'd380 && y>=10'd395 && y<=10'd400);

// home page
always_comb begin
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
    else if ((mode==1'b0) && boundary1) begin
        vga_r_n = 8'd20;
        vga_g_n = 8'd255;
        vga_b_n = 8'd255;
    end
    else if ((mode==1'b1) && boundary2) begin
        vga_r_n = 8'd20;
        vga_g_n = 8'd255;
        vga_b_n = 8'd255;
    end
    else begin
        vga_r_n = 8'd50;
        vga_g_n = 8'd50;
        vga_b_n = 8'd50;
    end
end

always_comb begin
    // default value
    state_nxt = state;
    mode_nxt = mode;
    start_nxt = start;
    stop_nxt = stop;
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
            stop_nxt = 1'b0;
        end
        S_1P: begin
            if (i_key_1 == esc) begin
                state_nxt = S_IDLE;
                stop_nxt = 1'b1;
            end
            else begin
                state_nxt = state;
                stop_nxt = 1'b0;
            end
            start_nxt = 1'b0;
        end
        S_2P: begin
            if (i_key_1 == esc) begin
                state_nxt = S_IDLE;
                stop_nxt = 1'b1;
            end
            else if (finish_1 || finish_2) begin
                state_nxt = state;
                stop_nxt = 1'b1;
            end
            else begin
                state_nxt = state;
                stop_nxt = 1'b0;
            end
            start_nxt = 1'b0;
        end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state <= 2'b00;
        mode <= 1'b0;
        start <= 1'b0;
        stop <= 1'b0;
        vga_r <= 8'd0;
        vga_g <= 8'd0;
        vga_b <= 8'd0;
    end
    else begin
        state <= state_nxt;
        mode <= mode_nxt;
        start <= start_nxt;
        stop <= stop_nxt;
        vga_r <= vga_r_n;
        vga_g <= vga_g_n;
        vga_b <= vga_b_n;
    end
end

endmodule