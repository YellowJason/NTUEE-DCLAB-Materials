`timescale 1ns/10ps

module tb;
    // address and rw
    localparam audio_dat = 16'b1110101010101011;
    localparam audio_dat2 = 16'b1011101110101001;
    // reg and data


	localparam CLK = 10;
	localparam HCLK = CLK/2;

    logic rst, clk, start, pause, stop;
    logic i_AUD_ADCLRCK = 1'b1;
    logic i_AUD_ADCDAT;
    logic [19:0] addr;
    logic [15:0] data_record;
    logic [19:0] addr_counter;
    logic [15:0] hold_data;

	initial clk = 1;
	always #HCLK clk = ~clk;

    AudRecorder recorder0(
        .i_rst_n(rst), 
        .i_clk(clk),
        .i_lrc(i_AUD_ADCLRCK),
        .i_start(start),
        .i_pause(pause),
        .i_stop(stop),
        .i_data(i_AUD_ADCDAT),
        .o_address(addr),
        .o_data(data_record),
        .o_addr_counter(addr_counter),
        .o_hold_data(hold_data)
    );

	initial begin
        $fsdbDumpfile("audRec.fsdb");
		$fsdbDumpvars;
        $display("reset...");
        rst = 1;
		#(2*CLK)
		rst = 0;
		#(2*CLK)
        rst=1;
        pause = 0;

        $display("start...");
        start = 1;
        stop = 0;
        i_AUD_ADCLRCK = 1'b1;
        #CLK
        start = 0;

        // start I2S comm
        #(4.5*CLK)
        i_AUD_ADCLRCK = 1'b0;
        #(0.5*CLK)
        for (int i = 0; i < 16; i = i + 1) begin
            @(negedge clk)
            i_AUD_ADCDAT = audio_dat[i];
            $display("%1d, audio_dat[i] = %1d, i_AUD_ADCDAT = %1d", i, audio_dat[i], i_AUD_ADCDAT);
        end
        #CLK
        i_AUD_ADCDAT = 16'bx;
        #(5*CLK)
        i_AUD_ADCLRCK = 1'b1;
        #(20*CLK)

        i_AUD_ADCLRCK = 1'b0;
        #CLK
        for (int i = 0; i < 16; i = i + 1) begin
            @(posedge clk)
            i_AUD_ADCDAT = audio_dat2[i];
        end
        #CLK
        i_AUD_ADCDAT = 16'bx;
        #(5*CLK)
        i_AUD_ADCLRCK = 1'b1;
        #(2*CLK)
        
        stop = 1;
        #(CLK)
        i_AUD_ADCLRCK = 1'b0;
        #(20*CLK)

        $display("finish");
        $finish;
	end

    initial begin
		#(5000000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
