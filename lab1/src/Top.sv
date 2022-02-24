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
				random_num_gen_nxt = random_num_gen ^ counter;
			end
			else begin
				state_nxt = state;
				out_nxt = out;
				counter_run_nxt = 26'b0;
				random_num_gen_nxt = random_num_gen;
			end
		end
		S_PROC: begin
			// 用一個 counter 計算取隨機數的時間
			counter_run_nxt = counter_run + 1;
			// 跑 1.2 秒後回到 IDLE
			if (counter_run == 26'b11111111111111111111111111) begin
				state_nxt = S_IDLE;
			end
			else begin
				state_nxt = state;
			end
			// Linear feedback shift register
			random_num_gen_nxt[15] = random_num_gen[0] ^ random_num_gen[2] ^ random_num_gen[3] ^ random_num_gen[5];
			random_num_gen_nxt[14:0] = random_num_gen[15:1];
			if(counter_run <= 8'd13427772) begin
				if(counter_run % 7'd2685554 == 0) begin
					out_nxt = random_num_gen[3:0];
				end
				else
					out_nxt = out;
				end
			end
			if(counter_run <= 8'd26855544) begin
				if(counter_run % 7'd6713886 == 0) begin
					out_nxt = random_num_gen[3:0];
				end
				else
					out_nxt = out;
				end
			end	
			if(counter_run <= 8'd40283316) begin
				if(counter_run % 8'd13427772 == 0) begin
					out_nxt = random_num_gen[3:0];
				end
				else
					out_nxt = out;
				end
			end	
			if(counter_run <= 8'd53711088) begin
				if(counter_run % 8'd26855544 == 0) begin
					out_nxt = random_num_gen[3:0];
				end
				else
					out_nxt = out;
				end
			end	
			if(counter_run <= 8'd67138860) begin
				if(counter_run % 8'd67138860 == 0) begin
					out_nxt = random_num_gen[3:0];
				end
				else
					out_nxt = out;
				end
			end	
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
		random_num_gen <=  16'b0;
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
