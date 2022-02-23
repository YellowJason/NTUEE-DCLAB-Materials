module Top (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
	output [3:0] o_random_out
);

// ===== States =====
parameter S_IDLE = 1'b0;
parameter S_PROC = 1'b1;

// ===== Output Buffers =====
logic [3:0] out, out_nxt;

// ===== Registers & Wires =====
logic state, state_nxt;

// 16 bits counter for seed
logic [15:0] counter, counter_nxt;

// 26 bits counter for runing time
logic [25:0] counter_run, counter_run_nxt;

// random number generator
logic [15:0] random_num_gen, random_num_gen_nxt;

// ===== Output Assignments =====
assign o_random_out = out;

// ===== Combinational Circuits =====
always_comb begin
	counter_nxt = counter + 1;
	// FSM
	case(state)
		S_IDLE: begin
			// 按下 start 按鈕
			if (i_start) begin
				state_nxt = S_PROC;
				out_nxt = 4'b0;
				counter_run_nxt = 26'b0;
			end
		end
		S_PROC: begin
			counter_run_nxt = counter_run + 1;
			o_random_out_nxt = ;		//todo
			if (counter_run == 26'b11111111111111111111111111) begin
				state_nxt = S_IDLE;
			end
			random_num_gen_nxt[15] = random_num_gen[0]^random_num_gen[2]^random_num_gen[3]^random_num_gen[5];
			random_num_gen_nxt[14:0] = random_num_gen[15:1];
			out = random_num_gen[3:0];
		end
	endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin	//flipflop
	// reset
	if (!i_rst_n) begin
		out <= 4'b0;
		state        <= S_IDLE;
		counter		 <= 16'b0;
		counter_run  <= 26'b0;
	end
	else begin
		out <= out_nxt;
		state        <= state_nxt;
		counter      <= counter_nxt;
		counter_run  <= counter_run_nxt;
		random_num_gen <=  random_num_gen_nxt;        
	end
	
end

endmodule
