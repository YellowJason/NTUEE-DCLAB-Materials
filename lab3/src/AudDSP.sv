module AudDSP(
    input i_rst_n,
    input i_clk,
    input i_start,
    input i_pause,
    input i_stop,
    input i_speed,
    input i_fast,
    input i_slow_0,
    input i_slow_1,
    inout i_daclrck,
    input [19:0] last_mem,
    input [15:0] i_sram_data,
    output [15:0] o_dac_data,
    output [19:0] o_sram_addr
);

parameter S_IDLE = 2'b00;
parameter S_PLAY = 2'b01;
parameter S_PAUS = 2'b10;

// 3 states
logic [1:0] state, state_nxt;

// daclrck
logic daclrck, daclrck_nxt;
assign daclrck_nxt = i_daclrck;

// output buffer
logic [19:0] sram_addr, sram_addr_nxt;
assign o_sram_addr = sram_addr;

always_comb begin
    case(state)
        S_IDLE: begin
            if (i_start) begin
                state_nxt = S_PLAY;
            end
            else begin
                state_nxt = S_IDLE;
            end
        end
        S_PLAY: begin
            if (i_pause) begin
                state_nxt = S_PAUS;
            end
            else begin
                state_nxt = S_PLAY;
            end
        end
        S_PAUS: begin
            if (i_start) begin
                state_nxt = S_PLAY;
            end
            else begin
                state_nxt = S_PAUS;
            end
        end
        default: begin
            state_nxt = state;
        end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state <= S_IDLE;
        daclrck <= 1'b0;
    end
    else begin
        state <= state_nxt;
        daclrck <= daclrck_nxt;
    end
end
endmodule