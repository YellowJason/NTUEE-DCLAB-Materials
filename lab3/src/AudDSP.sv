// AudDSP dsp0(
// 	.i_rst_n(i_rst_n),
// 	.i_clk(),
// 	.i_start(),
// 	.i_pause(),
// 	.i_stop(),
// 	.i_speed(),
// 	.i_fast(),
// 	.i_slow_0(), // constant interpolation
// 	.i_slow_1(), // linear interpolation
// 	.i_daclrck(i_AUD_DACLRCK),
// 	.i_sram_data(data_play),
// 	.o_dac_data(dac_data),
// 	.o_sram_addr(addr_play)
// );

module AudDSP(
    input i_rst_n,
    input i_clk,
    input i_start,
    input i_pause,
    input i_stop,
    input i_speed,
    input i_fast,
    input i_slow_0,
    input i_slow_1,
    inout i_daclrck,
    input [15:0] i_sram_data,
    output [15:0] o_dac_data,
    output [19:0] o_sram_addr
);