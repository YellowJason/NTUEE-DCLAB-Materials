module Top (
	input i_rst_n,		// key 3
	input i_clk,
	input i_start,		// key 0
	input i_pause,		// key 1
	input i_stop,		// key 2
	input i_rec_play,	// SW[0]	0:record, 1:play
	input [1:0] i_mode,	// SW[2:1]	00:normal , 10:fast, 01:slow_0, 11:slow_1
	input [3:0] i_speed,// SW[5:3]	1~8 times speed
	
	// AudDSP and SRAM
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,
	
	// I2C
	input  i_clk_2,
	output o_I2C_SCLK,
	inout  io_I2C_SDAT,
	
	// AudPlayer
	input  i_AUD_ADCDAT,
	inout  i_AUD_ADCLRCK,
	inout  i_AUD_BCLK,
	inout  i_AUD_DACLRCK,
	output o_AUD_DACDAT,

	// SEVENDECODER (optional display)
	output [4:0] hex0,
	output [4:0] hex1,
	output [4:0] hex2,
	output [4:0] hex3,

	// LCD (optional display)
	// input        i_clk_800k,
	// inout  [7:0] o_LCD_DATA,
	// output       o_LCD_EN,
	// output       o_LCD_RS,
	// output       o_LCD_RW,
	// output       o_LCD_ON,
	// output       o_LCD_BLON,

	// LED
	// output  [8:0] o_ledg,
	output [17:0] o_ledr
);

// design the FSM and states as you like
parameter S_IDLE       = 2'd0;
parameter S_I2C        = 2'd1;
parameter S_RECD       = 2'd2;
parameter S_PLAY       = 2'd3;

logic [1:0] state, state_nxt;
wire i2c_oen, i2c_sdat;									// I2C transmit line
logic [19:0] addr_record, addr_play;					// sram address
logic [15:0] data_record, data_play, dac_data;			// for: recorder, DSP, player
logic o_i2c_finished, i_i2c_start;						// I2C control signal
logic i_en_audplayer;									// player enable
logic i_AUD_CLK;										// clock for DSP
assign i_AUD_CLK = i_AUD_BCLK;							// same clock as WM8731
logic [19:0] last_addr, last_addr_nxt, last_addr_temp;	// last data address	
assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

assign o_SRAM_ADDR = (state == S_RECD) ? addr_record : addr_play;
assign io_SRAM_DQ  = (state == S_RECD) ? data_record : 16'dz; // sram_dq as output
assign data_play   = (state != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input

assign o_SRAM_WE_N = (state == S_RECD) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

// below is a simple example for module division
// you can design these as you like

// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal
I2cInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_2),
	.i_start(i_i2c_start),
	.o_finished(o_i2c_finished),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)
);

// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player
// fetch data from SRAM and send it to player (according to selected speed)
// AudDSP dsp0(
// 	.i_rst_n(i_rst_n),
// 	.i_clk(i_AUD_CLK),
// 	.i_start(i_play_start),
// 	.i_pause(i_play_pause),
// 	.i_stop(i_play_stop),
// 	.i_speed(i_play_speed),
// 	.i_fast(i_play_fast),
// 	.i_slow_0(i_play_slow_0), // constant interpolation
// 	.i_slow_1(i_play_slow_1), // linear interpolation
// 	.i_daclrck(i_AUD_DACLRCK),
// 	.i_sram_data(data_play),
// 	.o_dac_data(dac_data),
// 	.o_sram_addr(addr_play)
// );
logic start_play;
//logic stop_play;
assign start_play = (i_start & i_rec_play);
//assign stop_play = (i_stop & i_rec_play);

AudDSP dsp0(
    .i_rst_n(i_rst_n),
	.i_clk(i_AUD_CLK),
	.i_start(start_play),
	.i_pause(i_pause),
	.i_stop(i_stop),
	.i_speed(i_speed),			// 0 -> 1*speed, 7 -> 8*speed
    .mode(i_mode),      		// 4 mode [1:0]
    .i_daclrck(i_AUD_DACLRCK),
    .i_last_mem(last_addr),		//[19:0]
    .i_sram_data(data_play),
	.o_dac_data(dac_data),
	.o_sram_addr(addr_play)
);

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(i_en_audplayer), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data), //dac_data
	.o_aud_dacdat(o_AUD_DACDAT)
);

// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
logic start_rec;
//logic stop_rec;
assign start_rec = (i_start & !i_rec_play);
//assign stop_rec = (i_stop & !i_rec_play);

AudRecorder recorder0(
	.i_rst_n(i_rst_n), 
	.i_clk(i_AUD_BCLK),
	.i_lrc(i_AUD_ADCLRCK),
	.i_start(start_rec),
	.i_pause(i_pause),
	.i_stop(i_stop),
	.i_data(i_AUD_ADCDAT),
	.o_address(addr_record),
	.o_data(data_record),
	.o_addr_counter(last_addr_temp)
);

always_comb begin
	// design your control here
	// default
	i_i2c_start = 1'b0;
	i_en_audplayer = 1'b0;
	last_addr_nxt = last_addr;

	case(state)
		S_IDLE: begin
			if(i_start) begin
				state_nxt = i_rec_play ? S_PLAY : S_RECD;
			end
			else begin
				state_nxt = S_IDLE;
			end
		end
		S_I2C: begin
			if (o_i2c_finished) begin
				i_i2c_start = 1'b0;
				state_nxt = S_IDLE;
			end
			else begin
				i_i2c_start = 1'b1;
				state_nxt = S_I2C;
			end
		end
		S_RECD: begin
			if (i_stop || (~addr_record == 20'b0)) begin
				state_nxt = S_IDLE;
				last_addr_nxt = last_addr_temp;
			end
			else begin
				state_nxt = S_RECD;
				last_addr_nxt = last_addr;
			end
		end
		S_PLAY: begin
			if (i_stop || (addr_play >= last_addr)) begin
				state_nxt = S_IDLE;
				i_en_audplayer = 1'b0;
			end
			else begin
				state_nxt = S_PLAY;
				i_en_audplayer = 1'b1;
			end
		end
	endcase
end

always_ff @(negedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state <= S_I2C;
		last_addr <= 20'b0;
	end
	else begin
		state <= state_nxt;
		last_addr <= last_addr_nxt;
	end
end

// Seven hex decoder
assign hex0 = addr_play[19:15];
assign hex1 = addr_record[19:15];
assign hex2 = i_speed + 1;
assign hex3 = state;

// LED volume
logic [17:0] vol_reco;
logic [17:0] vol_play;
assign o_ledr = (state == S_RECD) ? vol_reco :
				(state == S_PLAY) ? vol_play : 18'b0;

always_comb begin
	if (~data_record[15]) begin
		vol_reco = {data_record[14:10] == 5'd31, data_record[14:10] >= 5'd29, data_record[14:10] >= 5'd27,
					data_record[14:10] >= 5'd25, data_record[14:10] >= 5'd23, data_record[14:10] >= 5'd21,
					data_record[14:10] >= 5'd19, data_record[14:10] >= 5'd17, data_record[14:10] >= 5'd15,
					data_record[14:10] >=  5'd3, data_record[14:10] >= 5'd11, data_record[14:10] >=  5'd9,
					data_record[14:10] >=  5'd7, data_record[14:10] >=  5'd6, data_record[14:10] >=  5'd5,
					data_record[14:10] >=  5'd4, data_record[14:10] >=  5'd3, data_record[14:10] >=  5'd2};
	end
	else begin
		vol_reco = {data_record[14:10] ==  5'd0, data_record[14:10] <=  5'd2, data_record[14:10] <=  5'd4,
					data_record[14:10] <=  5'd6, data_record[14:10] <=  5'd8, data_record[14:10] <= 5'd10,
                    data_record[14:10] <= 5'd12, data_record[14:10] <= 5'd14, data_record[14:10] <= 5'd16,
					data_record[14:10] <= 5'd18, data_record[14:10] <= 5'd20, data_record[14:10] <= 5'd22, 
                    data_record[14:10] <= 5'd24, data_record[14:10] <= 5'd25, data_record[14:10] <= 5'd26,
					data_record[14:10] <= 5'd27, data_record[14:10] <= 5'd28, data_record[14:10] <= 5'd29};
	end
end

always_comb begin
	if (~dac_data[15]) begin
		vol_play = {dac_data[14:10] == 5'd31, dac_data[14:10] >= 5'd29, dac_data[14:10] >= 5'd27, 
					dac_data[14:10] >= 5'd25, dac_data[14:10] >= 5'd23, dac_data[14:10] >= 5'd21, 
					dac_data[14:10] >= 5'd19, dac_data[14:10] >= 5'd17, dac_data[14:10] >= 5'd15, 
					dac_data[14:10] >= 5'd13, dac_data[14:10] >= 5'd11, dac_data[14:10] >=  5'd9, 
					dac_data[14:10] >=  5'd7, dac_data[14:10] >=  5'd6, dac_data[14:10] >=  5'd5, 
					dac_data[14:10] >=  5'd4, dac_data[14:10] >=  5'd3, dac_data[14:10] >=  5'd2};
	end
	else begin
		vol_play = {dac_data[14:10] ==  5'd0, dac_data[14:10] <=  5'd2, dac_data[14:10] <=  5'd4,
					dac_data[14:10] <=  5'd6, dac_data[14:10] <=  5'd8, dac_data[14:10] <= 5'd10,
                    dac_data[14:10] <= 5'd12, dac_data[14:10] <= 5'd14, dac_data[14:10] <= 5'd16,
					dac_data[14:10] <= 5'd18, dac_data[14:10] <= 5'd20, dac_data[14:10] <= 5'd22,
                    dac_data[14:10] <= 5'd24, dac_data[14:10] <= 5'd25, dac_data[14:10] <= 5'd26,
					dac_data[14:10] <= 5'd27, dac_data[14:10] <= 5'd28, dac_data[14:10] <= 5'd29};
	end
end
//////////////////////////// debug ////////////////////////////
/*
logic [23:0] counter_12m, counter_100k, counter_aud;
assign hex0 = counter_12m[23:20];
assign hex1 = counter_100k[23:20];
assign hex2 = counter_aud[23:20];
assign hex3 = state;

always_ff @(negedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		counter_12m <= 24'b0;
	end
	else begin
		counter_12m <= counter_12m + 1;
	end
end

always_ff @(negedge i_AUD_BCLK or negedge i_rst_n) begin
	if (!i_rst_n) begin
		counter_aud <= 24'b0;
	end
	else begin
		counter_aud <= counter_aud + 1;
	end
end

always_ff @(negedge i_clk_2 or negedge i_rst_n) begin
	if (!i_rst_n) begin
		counter_100k <= 24'b0;
	end
	else begin
		counter_100k <= counter_100k + 1;
	end
end
*/
endmodule