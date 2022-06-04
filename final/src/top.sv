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

// home page
always_comb begin
    if (mode == 1'b0) begin
        vga_r_n = 8'd255;
        vga_g_n = 8'd255;
        vga_b_n = 8'd20;
    end
    else begin
        vga_r_n = 8'd20;
        vga_g_n = 8'd20;
        vga_b_n = 8'd255;
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