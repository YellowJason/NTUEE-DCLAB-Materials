// AudPlayer player0(
// 	.i_rst_n(i_rst_n),
// 	.i_bclk(i_AUD_BCLK),
// 	.i_daclrck(i_AUD_DACLRCK),
// 	.i_en(), // enable AudPlayer only when playing audio, work with AudDSP
// 	.i_dac_data(dac_data), //dac_data
// 	.o_aud_dacdat(o_AUD_DACDAT)
// );
module AudPlayer (
    input i_rst_n,
    inout i_bclk,
    inout i_AUD_DACLRCK,
    input i_en,
    input [15:0] i_dac_data,
    output o_aud_dacdat

);