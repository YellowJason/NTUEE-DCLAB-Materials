// Implement I2C to intialize wm8731
module I2CInitializer(
input	i_rst_n,
input	i_clk,
input 	i_start,
output	o_finished,
output	o_sclk,
inout	o_sdat,
output	o_oen,  // you are outputing (you are not outputing only when you are "ack"ing.)

output [1:0] o_state
);

// state
localparam S_IDLE 	 = 0; // idle, initial state
localparam S_START 	 = 1; // start setting
localparam S_SETTING = 2; // setting state, which will send data through i2c to wm8731
localparam S_FINISH  = 3; // finish setup
// address and rw
localparam Address = 7'b0011010; // wm8731 address
localparam RW = 1'b0; // i2c writing (0)
// reg and data
// below four use default instead
// localparam Left_Line_In 				  = 16'b0000000010010111;
// localparam Right_Line_In 				  = 16'b0000001010010111;
// localparam Left_Headphone_Out             = 16'b0000010001111001;
// localparam Right_Headphone_Out            = 16'b0000011001111001;
localparam Reset 						  = 16'b0001111000000000;
localparam Analogue_Audio_Path_Control 	  = 16'b0000100000010101;
localparam Digital_Audio_Path_Control 	  = 16'b0000101000000000;
localparam Power_Down_Control 			  = 16'b0000110000000000;
localparam Digital_Audio_Interface_Format = 16'b0000111001000010;
localparam Sampling_Control 			  = 16'b0001000000011001;
localparam Active_Control 				  = 16'b0001001000000001;

logic [1:0] state_r, state_w; // state
logic [15:0] reg_data_r, reg_data_w; // reg and data
logic [2:0] counter_r, counter_w; // counter from 0 to 6, which is to send reg and data
logic start_r, start_w; // tell i2c module to start
logic fin_r, fin_w;     // tell upper this initialize finished

logic [6:0] addr = Address; // chip Address
logic rw = RW; // chip RW
logic i2c_fin; // get i2c finish or not

assign o_finished = fin_r;

assign o_state = state_r;

I2C i2c(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk),
	.i_start(start_r),
	.i_addr(addr),
	.i_rw(rw),
	.i_reg_data(reg_data_r),

	.o_finished(i2c_fin),
	.o_sclk(o_sclk),
	.o_sdat(o_sdat),
	.o_oen(o_oen)
);

always_comb begin
	state_w = state_r;
	reg_data_w = reg_data_r;
	counter_w = counter_r;
	start_w = start_r;
	fin_w = fin_r;
	case (state_r)

		S_IDLE: begin
			start_w = 1'b0;
			fin_w = 1'b0;
			counter_w = 3'b0;
			if (i_start) begin
				state_w = S_START;
			end
		end

		S_START: begin
			if (counter_r <= 6) begin
				start_w = 1'b1;
				state_w = S_SETTING;
				case (counter_r)
					0: begin reg_data_w = Reset; end
					// below four use default instead
					// 1: begin reg_data_w = Left_Line_In; end
					// 2: begin reg_data_w = Right_Line_In; end
					// 3: begin reg_data_w = Left_Headphone_Out; end
					// 4: begin reg_data_w = Right_Headphone_Out; end  
					1: begin reg_data_w = Analogue_Audio_Path_Control; end
					2: begin reg_data_w = Digital_Audio_Path_Control; end
					3: begin reg_data_w = Power_Down_Control; end
					4: begin reg_data_w = Digital_Audio_Interface_Format; end
					5: begin reg_data_w = Sampling_Control; end
					6: begin reg_data_w = Active_Control; end
					default: begin
						reg_data_w = Reset;
					end
				endcase
			end
			else begin
				state_w = S_FINISH;
			end
		end

		S_SETTING: begin
			start_w = 1'b0; // pull down start for i2c module to work correctly
			if (i2c_fin) begin // i2c will pull this up when finished, then pull this down
				state_w = S_START;
				counter_w = counter_r + 3'b1;
			end
		end
		
		S_FINISH: begin
			fin_w = 1'b1;
			// state_w = S_IDLE; maybe don't need to jump back to idle
		end
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	// design your control here
    if (!i_rst_n) begin
		state_r <= S_IDLE;
		reg_data_r <= 16'b0;
		counter_r <= 3'b0;
		start_r <= 1'b0;
		fin_r <= 1'b0;
	end
	else begin
		state_r <= state_w;
		reg_data_r <= reg_data_w;
		counter_r <= counter_w;
		start_r <= start_w;
		fin_r <= fin_w;
	end
end
endmodule