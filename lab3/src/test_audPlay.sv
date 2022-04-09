`timescale 1ns/10ps

module tb;
    // address and rw
    localparam audio_dat1 = 16'b1010101010101010;
    localparam audio_dat2 = 16'b1110111110101111;
    localparam audio_dat3 = 16'b1010111110101111;
    // reg and data

	localparam CLK = 10;
	localparam HCLK = CLK/2;

    logic rst, clk, en;
    logic i_AUD_DACLRCK = 1'b1;
    logic o_AUD_DACDAT;
    logic [19:0] addr;
    logic [15:0] data_record;

	initial clk = 0;
	always #HCLK clk = ~clk;    //every 5 ns clk -> -clk
    initial i_AUD_DACLRCK = 1'b1;
    always begin  
        #(30*CLK);          //after 30 clk 
        i_AUD_DACLRCK = ~i_AUD_DACLRCK;     //aud clock turn into negative
        #CLK;
    end

    initial begin
        data_record = audio_dat1;
        #(60*CLK)
        data_record = audio_dat2;
        #(60*CLK)
        data_record = audio_dat3;
        
    end

    AudPlayer player0(
        .i_rst_n(rst),
        .i_bclk(clk),
        .i_daclrck(i_AUD_DACLRCK),
        .i_en(en), // enable AudPlayer only when playing audio, work with AudDSP
        .i_dac_data(data_record), //dac_data
        .o_aud_dacdat(o_AUD_DACDAT)
    );

	initial begin
        $fsdbDumpfile("audPlay.fsdb");
		$fsdbDumpvars;
        $display("reset...");
        rst = 1;
		#(2*CLK)        // 2 cycle 
		rst = 0;
		#(2*CLK)
        rst=1;

        $display("start...");
        en = 1;

        // i_AUD_DACLRCK = 1'b1;
        // #(30*CLK)
        // i_AUD_DACLRCK = 1'b0;
        // #CLK
        for (int i = 0; i < 90; i = i + 1) begin
            @(negedge clk)
            $display("DAC= %1d", o_AUD_DACDAT);
        end
        #CLK
        i_AUD_DACLRCK = 1'b1;
        #(200*CLK)

        // @(posedge fin)
        $display("finish");
        $finish;
	end

    initial begin
		#(5000000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
