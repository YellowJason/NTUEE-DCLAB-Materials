module Keyboard(
    input i_clk,
    input i_rst_n,
    // PS2 input signal
    input i_data,
    input i_ps2_clk,
    // output signal
    output [7:0] o_data,
    output o_finish
);

parameter S_IDLE = 1'b0;
parameter S_READ = 1'b1;

logic state, state_nxt;

// detect negedge i_ps2_clk
logic ps2_clk_mem;

// counter for reading
logic [3:0] counter_read, counter_read_nxt;

// reading data
logic [7:0] data, data_nxt;
assign o_data = data;

// finish signal
logic finish, finish_nxt;
assign o_finish = finish;

always_comb begin
    case(state)
        S_IDLE: begin
            counter_read_nxt = 4'b0;
            finish_nxt = 1'b0;
            // start read when negedge i_ps2_clk
            if (ps2_clk_mem & !i_ps2_clk) begin
                state_nxt = S_READ;
                data_nxt = 8'b0;
            end
            else begin
                state_nxt = state;
                data_nxt = data;
            end
        end
        S_READ: begin
            if (counter_read == 4'd10) begin
                state_nxt = S_IDLE;
                counter_read_nxt = 4'b0;
                data_nxt = data;
                finish_nxt = 1'b1;
            end
            else if ((counter_read == 4'd9) | (counter_read == 4'd8)) begin
                state_nxt = state;
                counter_read_nxt = counter_read + 1;
                data_nxt = data;
                finish_nxt = 1'b0;
            end
            else begin
                state_nxt = state;
                counter_read_nxt = counter_read + 1;
                data_nxt = {i_data, data[7:1]};
                finish_nxt = 1'b0;
            end
        end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state <= 1'b0;
        ps2_clk_mem <= 1'b0;
        finish <= 1'b0;
    end
    else begin
        state <= state_nxt;
        ps2_clk_mem <= i_ps2_clk;
        finish <= finish_nxt;
    end
end

always_ff @(negedge i_ps2_clk or negedge i_rst_n)begin
    if (!i_rst_n)begin
        counter_read <= 4'b0;
        data <= 8'b0;
    end
    else begin
        counter_read <= counter_read_nxt;
        data <= data_nxt;
    end
end

endmodule