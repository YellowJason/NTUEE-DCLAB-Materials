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

endmodule