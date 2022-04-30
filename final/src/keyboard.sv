module Keyboard(
    input i_clk,
    input i_rst_n,
    // PS2 input signal
    input i_data,
    input i_ps2_clk,
    // output signal
    output [7:0] o_data,
    output [7:0] o_data_down,
    output o_finish
);

// 2 states
parameter S_IDLE = 1'b0;
parameter S_READ = 1'b1;

// key value we want to detect
parameter up = 8'h75;
parameter down = 8'h72;
parameter right = 8'h74;
parameter left = 8'h6b;

logic state, state_nxt;

// detect negedge i_ps2_clk
logic ps2_clk_mem;

// counter for reading
logic [3:0] counter_read, counter_read_nxt;

// reading data
logic [7:0] data, data_nxt;
logic [7:0] data_out, data_out_nxt;
assign o_data_down = data;
assign o_data = data_out;

// finish signal
logic finish, finish_nxt;
assign o_finish = finish;

// counter for debounce
logic [9:0] counter_de, counter_de_nxt;

always_comb begin
    case(state)
        S_IDLE: begin
            counter_read_nxt = 4'b0;
            finish_nxt = 1'b0;
            data_nxt = 8'b0;
            counter_de_nxt = counter_de + 1;
            // start read when negedge i_ps2_clk
            if (ps2_clk_mem & !i_ps2_clk) begin
                state_nxt = S_READ;
            end
            else begin
                state_nxt = state;
            end
            // set o_data to 0 if no signal in 16 cycles
            // data_out_nxt = (counter_de == 10'd1023) ? 8'b0 : data_out;
            data_out_nxt = data_out;
        end
        S_READ: begin
            counter_de_nxt = 10'b0;
            // update counter_read when negedge i_ps2_clk
            if (ps2_clk_mem & !i_ps2_clk) counter_read_nxt = counter_read + 1;
            else                          counter_read_nxt = counter_read;
            if (counter_read == 4'd10) begin
                state_nxt = S_IDLE;
                data_nxt = 8'b0;
                data_out_nxt = data_out;
                finish_nxt = 1'b1;
            end
            else if ((counter_read == 4'd9) | (counter_read == 4'd8)) begin
                state_nxt = state;
                data_nxt = data;
                // check if we want the pressed key
                if ((data == up) || (data == down) || (data == right) || (data == left)) begin
                    data_out_nxt = data;
                end
                else begin
                    data_out_nxt = data_out;
                end
                finish_nxt = 1'b0;
            end
            else begin
                state_nxt = state;
                if (ps2_clk_mem & !i_ps2_clk) data_nxt = {i_data, data[7:1]};
                else                          data_nxt = data;
                data_out_nxt = data_out;
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
        counter_read <= 4'b0;
        data <= 8'b0;
        data_out <= 8'b0;
        counter_de <= 10'b0;
    end
    else begin
        state <= state_nxt;
        ps2_clk_mem <= i_ps2_clk;
        finish <= finish_nxt;
        counter_read <= counter_read_nxt;
        data <= data_nxt;
        data_out <= data_out_nxt;
        counter_de <= counter_de_nxt;
    end
end
/*
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
*/
endmodule