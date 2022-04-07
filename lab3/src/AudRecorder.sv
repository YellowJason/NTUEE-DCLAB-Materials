// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
module AudRecorder (
	input i_rst_n, 
	inout i_clk,
	inout i_lrc,
	input i_start,
	input i_pause,
	input i_stop,
	input i_data,
	output [19:0] o_address,
	output [15:0] o_data
);

localparam IDLE         = 2'b00;
localparam WAIT_1_CYCLE = 2'b01;
localparam RECORDING    = 2'b10;
localparam FINISH       = 2'b11;

logic [1:0]  state, state_nxt;
logic [3:0]  counter, counter_nxt;
logic [19:0] rec_addr, rec_addr_nxt;
logic [15:0] rec_data, rec_data_nxt;
logic lrc, lrc_nxt;

parameter counter_end = 4'd15;

assign o_address = rec_addr;
assign o_data = rec_data;

always_comb begin
	case(state)
        IDLE:begin
            state_nxt = i_start ? WAIT_1_CYCLE : state;
            counter_nxt = counter;
            rec_addr_nxt = rec_addr;
            rec_data_nxt = rec_data;
            lrc_nxt = lrc;
        end
        WAIT_1_CYCLE:begin
            state_nxt = (lrc && !lrc_nxt) ? RECORDING : state; // handle left channel
            counter_nxt = counter;
            rec_addr_nxt = rec_addr;
            rec_data_nxt = rec_data;
            lrc_nxt = lrc;
        end
        RECORDING:begin
            state_nxt = (counter == counter_end) ? FINISH : state;
            counter_nxt = (counter == counter_end) ? 4'd0 : counter+1;
            rec_data_nxt = {rec_data[14:0], i_data};
            rec_addr_nxt = rec_addr;
            lrc_nxt = lrc;
        end
        FINISH:begin
            state_nxt = (i_pause || i_stop) ? IDLE : WAIT_1_CYCLE;
            counter_nxt = counter;
            rec_addr_nxt = i_stop ? 20'd0 : rec_addr+1;
            rec_data_nxt = rec_data;
            lrc_nxt = lrc;
        end
    endcase
end

always_ff @(posedge i_clk or posedge i_rst_n) begin
	if (!i_rst_n) begin
        state <= IDLE;
        counter <= 4'd0;
        rec_addr <= 20'd0;
        rec_data <= 16'd0;
		lrc <= i_lrc;
	end
	else begin
        state <= state_nxt;
        counter <= counter_nxt;
        rec_addr <= rec_addr_nxt;
        rec_data <= rec_data_nxt;
		lrc <= lrc_nxt;
	end
end

endmodule