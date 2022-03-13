module Rsa256Core (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x
	output         o_finished
);
parameter S_IDLE = 2'b00;
parameter S_PREP = 2'b01;
parameter S_MONT = 2'b10;
parameter S_CALC = 2'b11;

// states
logic [1:0] state, state_nxt;

// counter for module of products
logic [7:0] counter_prep, counter_prep_nxt;

// counter for one iteration of Montgomery
logic [7:0] counter_mont, counter_mont_nxt;

// counter for full Montgomery
logic [7:0] counter_calc, counter_calc_nxt;

always_comb begin
	case(state)
		S_IDLE:begin
			// unchanged register
			counter_prep_nxt = counter_prep;
			counter_mont_nxt = counter_mont;
			counter_calc_nxt = counter_calc;
			//
			if (i_start) begin
				state_nxt = S_PREP;
			end
			else begin
				state_nxt = state;
			end
		end
		S_PREP:begin
			// unchanged register 
			counter_mont_nxt = counter_mont;
			counter_calc_nxt = counter_calc;
			//
			if (counter_prep == 8'b11111111) begin
				state_nxt = S_MONT;
				counter_prep_nxt = 8'b0;
			end
			else begin
				state_nxt = state;
				counter_prep_nxt = counter_prep + 1;
			end
		end
		S_MONT:begin
			// unchanged register 
			counter_prep_nxt = counter_prep;
			counter_calc_nxt = counter_calc;
			//
			if (counter_mont == 8'b11111111) begin
				state_nxt = S_CALC;
				counter_mont_nxt = 8'b0;
			end
			else begin
				state_nxt = state;
				counter_mont_nxt = counter_mont + 1;
			end
		end
		S_CALC:begin
			// unchanged register 
			counter_prep_nxt = counter_prep;
			counter_mont_nxt = counter_mont;
			//
			if (counter_calc == 8'b11111111) begin
				state_nxt = S_IDLE;
				counter_calc_nxt = 8'b0;
			end
			else begin
				state_nxt = S_MONT;
				counter_calc_nxt = counter_calc + 1;
			end
		end
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin	//flipflop
	// reset
	if (!i_rst_n) begin
		state <= S_IDLE;
		counter_prep <= 8'b0;
		counter_mont <= 8'b0;
		counter_calc <= 8'b0;
	end
	// clock edge
	else begin
		state <= state_nxt;
		counter_prep <= counter_prep_nxt;
		counter_mont <= counter_mont_nxt;
		counter_calc <= counter_calc_nxt;
	end
end
// operations for RSA256 decryption
// namely, the Montgomery algorithm

endmodule
