// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
module AudRecorder (
	input i_rst_n, 
	input i_clk,
	input i_lrc,
	input i_start,
	input i_pause,
	input i_stop,
	input i_data,
	output [19:0] o_address,
	output [15:0] o_data,
    output [19:0] o_addr_counter // output total used memory use
);

localparam IDLE         = 2'b00;
localparam WAIT_NEGEDGE = 2'b01; // wait and check if negative edge of LRC occur
localparam RECORDING    = 2'b10;
localparam FINISH       = 2'b11;

logic [1:0]  state, state_nxt;
logic [3:0]  bit_counter, bit_counter_nxt;
logic [19:0] addr_counter, addr_counter_nxt;
logic [19:0] rec_addr, rec_addr_nxt;
logic [15:0] rec_data, rec_data_nxt;
logic lrc, lrc_nxt;

parameter bit_counter_end = 4'd15;

assign o_address = rec_addr;
assign o_data = rec_data;
assign o_addr_counter = addr_counter;

always_comb begin
    lrc_nxt = i_lrc;
	case(state)
        IDLE:begin
            state_nxt = i_start ? WAIT_NEGEDGE : state;
            bit_counter_nxt = bit_counter;
            addr_counter_nxt = addr_counter;
            rec_addr_nxt = rec_addr;
            rec_data_nxt = rec_data;
        end
        WAIT_NEGEDGE:begin
            state_nxt = (lrc && !lrc_nxt) ? RECORDING : state; // handle left channel
            bit_counter_nxt = bit_counter;
            addr_counter_nxt = addr_counter;
            rec_addr_nxt = rec_addr;
            rec_data_nxt = rec_data;
        end
        RECORDING:begin
            state_nxt = (bit_counter == bit_counter_end) ? FINISH : state;
            bit_counter_nxt = (bit_counter == bit_counter_end) ? 4'd0 : bit_counter+1;
            addr_counter_nxt = addr_counter;
            rec_addr_nxt = rec_addr;
            rec_data_nxt = {rec_data[14:0], i_data};
        end
        FINISH:begin
            state_nxt = (i_pause || i_stop || (~rec_addr == 20'b0)) ? IDLE : WAIT_NEGEDGE;
            bit_counter_nxt = bit_counter;
            addr_counter_nxt = i_stop ? addr_counter : addr_counter+1;
            rec_addr_nxt = i_stop ? 20'd0 : rec_addr+1;
            rec_data_nxt = 16'd0;
        end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
        state <= IDLE;
        bit_counter <= 4'd0;
        addr_counter <= 20'd0;
        rec_addr <= 20'd0;
        rec_data <= 16'd0;
		lrc <= 1'b0;
	end
	else begin
        state <= state_nxt;
        bit_counter <= bit_counter_nxt;
        addr_counter <= addr_counter_nxt;
        rec_addr <= rec_addr_nxt;
        rec_data <= rec_data_nxt;
		lrc <= lrc_nxt;
	end
end

endmodule