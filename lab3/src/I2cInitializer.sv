module I2cInitializer (
    input i_rst_n,
	input i_clk,
	input i_start,
	output o_finished,
	output o_sclk,
	inout  o_sdat,
	output o_oen // you are outputing (you are not outputing only when you are "ack"ing.)
);

parameter S_IDLE = 3'b000;
parameter S_STAR = 3'b001;
parameter S_PRE1 = 3'b010;
parameter S_TEMP = 3'b011; // templary finish (after 24'b transmitted)
parameter S_TRAN = 3'b100;
parameter S_WAIT = 3'b101; // wait for ack
parameter S_FINI = 3'b110;

// 7 states
logic [2:0] state, state_nxt;

// Output buffers
logic sda, sda_nxt;
logic scl, scl_nxt;
logic oen, oen_nxt;
logic fin, fin_nxt;
assign o_sdat = oen ? sda : 1'bz;
assign o_sclk = scl;
assign o_oen = oen;
assign o_finished = fin;

// All datas need to transmit
/*
parameter Reset = 24'b0011_0100_000_1111_0_0000_0000;
parameter AAPC  = 24'b0011_0100_000_0100_0_0001_0101;
parameter DAPC  = 24'b0011_0100_000_0101_0_0000_0000;
parameter PDC   = 24'b0011_0100_000_0110_0_0000_0000;
parameter DAIF  = 24'b0011_0100_000_0111_0_0100_0010;
parameter SC    = 24'b0011_0100_000_1000_0_0001_1001;
parameter AC    = 24'b0011_0100_000_1001_0_0000_0001;
logic [167:0] data;
assign data = {Reset, AAPC, DAPC, PDC, DAIF, SC, AC};
*/
logic [239:0] data;
/*
assign data = {
	24'b00110100_000_0000_0_1001_0111,
	24'b00110100_000_0001_0_1001_0111,
	24'b00110100_000_0010_0_0111_1001,
	24'b00110100_000_0011_0_0111_1001,
	24'b00110100_000_0100_0_0001_0101,
	24'b00110100_000_0101_0_0000_0000,
	24'b00110100_000_0110_0_0000_0000,
	24'b00110100_000_0111_0_0100_0010,
	24'b00110100_000_1000_0_0001_1001,
    24'b00110100_000_1001_0_0000_0001
};
*/
assign data = {
    24'b00110100_000_1001_0_0000_0001,
    24'b00110100_000_1000_0_0001_1001,
    24'b00110100_000_0111_0_0100_0010,
    24'b00110100_000_0110_0_0000_0000,
    24'b00110100_000_0101_0_0000_0000,
    24'b00110100_000_0100_0_0001_0101,
    24'b00110100_000_0011_0_0111_1001,
    24'b00110100_000_0010_0_0111_1001,
    24'b00110100_000_0001_0_1001_0111,
    24'b00110100_000_0000_0_1001_0111
};

// count which data should be transmit
logic [7:0] counter_data, counter_data_nxt;

// count if transmit 8 bits data
logic [3:0] counter_tran, counter_tran_nxt;

// count 4 cycles for end & restart
logic [1:0] counter_temp, counter_temp_nxt;

always_comb begin
	case(state)
		S_IDLE: begin
			counter_data_nxt = 8'b0;
			counter_tran_nxt = 4'b0;
			counter_temp_nxt = 2'b0;
			if (i_start) begin
				state_nxt = S_STAR;
				sda_nxt = 1'b0;
				scl_nxt = 1'b1;
				oen_nxt = 1'b1;
			end
			else begin
				state_nxt = state;
				sda_nxt = 1'b1;
				scl_nxt = 1'b1;
				oen_nxt = 1'b1;
			end
			fin_nxt = fin;
		end
		S_STAR: begin
			counter_data_nxt = counter_data;
			counter_tran_nxt = counter_tran;
			counter_temp_nxt = 2'b0;
			state_nxt = S_PRE1;
			sda_nxt = data[239];
			scl_nxt = 1'b0;
			oen_nxt = oen;
			fin_nxt = 1'b0;
		end
		S_PRE1: begin
			counter_data_nxt = counter_data;
			counter_tran_nxt = counter_tran;
			counter_temp_nxt = 2'b0;
			// transmit 8 bits
			if (counter_tran == 4'd8) begin
				state_nxt = S_WAIT;
				oen_nxt = 1'b0;
				scl_nxt = 1'b1;
				sda_nxt = sda;
			end
			// transmit all datas
			else if (counter_data == 8'd240) begin
				state_nxt = S_FINI;
				oen_nxt = 1'b1;
				scl_nxt = 1'b1;
				sda_nxt = 1'b0;
			end
			else begin
				state_nxt = S_TRAN;
				oen_nxt = oen;
				scl_nxt = 1'b1;
				sda_nxt = sda;
			end
			fin_nxt = 1'b0;
		end
		S_TEMP: begin
			counter_data_nxt = counter_data;
			counter_tran_nxt = counter_tran;
			counter_temp_nxt = counter_temp + 1;
			state_nxt = (counter_temp == 2'b11) ? S_PRE1 : S_TEMP;
			scl_nxt = !(counter_temp == 2'b11);
			oen_nxt = 1'b1;
			fin_nxt = 1'b0;
			case(counter_temp)
				2'b00: sda_nxt = 1'b1;
				2'b01: sda_nxt = 1'b1;
				2'b10: sda_nxt = 1'b0;
				2'b11: sda_nxt = 1'b0;
			endcase
		end
		S_TRAN: begin
			counter_data_nxt = counter_data + 1;
			counter_tran_nxt = counter_tran + 1;
			counter_temp_nxt = 2'b0;
			state_nxt = S_PRE1;
			oen_nxt = 1'b1; 
			sda_nxt = (counter_data == 239) ? 1'b0 : data[239-counter_data-1];
			scl_nxt = 1'b0;
			fin_nxt = 1'b0;
		end
		S_WAIT: begin
			counter_data_nxt = counter_data;
			counter_tran_nxt = 4'b0;
			counter_temp_nxt = 2'b0;
			oen_nxt = 1'b1;
			fin_nxt = 1'b0;
			// restart after 24'b transmitted
			if ((counter_data % 7'd24 == 0) & (counter_data != 8'd240)) begin
				state_nxt = S_TEMP;
				sda_nxt = 1'b0;
				scl_nxt = 1'b1;
			end
			else begin
				state_nxt = S_PRE1;
				sda_nxt = sda;
				scl_nxt = 1'b0;
			end
		end
		S_FINI: begin
			counter_data_nxt = 8'b0;
			counter_tran_nxt = 3'b0;
			counter_temp_nxt = 2'b0;
			state_nxt = S_FINI;
			sda_nxt = 1'b1;
			scl_nxt = 1'b1;
			oen_nxt = 1'b1;
			fin_nxt = 1'b1;
		end
		default: begin
			counter_data_nxt = counter_data;
			counter_tran_nxt = counter_tran;
			counter_temp_nxt = counter_temp;
			state_nxt = state;
			sda_nxt = sda;
			scl_nxt = scl;
			oen_nxt = oen;
			fin_nxt = fin;
		end
	endcase
end

always_ff @(negedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		counter_data <= 8'b0;
		counter_tran <= 3'b0;
		counter_temp <= 2'b0;
		state <= S_IDLE;
		sda <= 1'b1;
		scl <= 1'b1;
		oen <= 1'b0;
		fin <= 1'b0;
	end
	else begin
		counter_data <= counter_data_nxt;
		counter_tran <= counter_tran_nxt;
		counter_temp <= counter_temp_nxt;
		state <= state_nxt;
		sda <= sda_nxt;
		scl <= scl_nxt;
		oen <= oen_nxt;
		fin <= fin_nxt;
	end
end

endmodule