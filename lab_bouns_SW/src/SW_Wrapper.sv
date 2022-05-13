
`define REF_MAX_LENGTH              128
`define READ_MAX_LENGTH             128

`define REF_LENGTH                  128
`define READ_LENGTH                 128

//* Score parameters
`define DP_SW_SCORE_BITWIDTH        10

`define CONST_MATCH_SCORE           1
`define CONST_MISMATCH_SCORE        -4
`define CONST_GAP_OPEN              -6
`define CONST_GAP_EXTEND            -1

module SW_Wrapper (
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest
);

localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

// Feel free to design your own FSM!
localparam S_QUERY_RX = 3'b000;
localparam S_READ = 3'b001;
localparam S_WAIT_CALCULATE = 3'b010;
localparam S_QUERY_TX = 3'b011;
localparam S_SEND_DATA = 3'b100;

logic [255:0] n_r, n_nxt, d_r, d_nxt, enc_r, enc_nxt, dec_r, dec_nxt;
logic [2:0] state_r, state_nxt;
logic [6:0] bytes_counter_r, bytes_counter_nxt;
logic [4:0] avm_address_r, avm_address_nxt;
logic avm_read_r, avm_read_nxt, avm_write_r, avm_write_nxt;

logic rsa_start_r, rsa_start_nxt;
logic rsa_finished;
logic [255:0] rsa_dec;

parameter read_d_start = 7'd33;
parameter data_counter_end = 7'd64;
parameter write_data_end = 7'd31;

assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
assign avm_writedata = dec_r[247-:8];

// Remember to complete the port connection
reg [6:0] row, col;
reg ready, valid;
reg [9:0] align_s;
SW_core sw_core(
    .clk				(avm_clk),
    .rst				(avm_rst),

	.o_ready			(ready),
    .i_valid			(1'd0),
    .i_sequence_ref		(256'd0),
    .i_sequence_read	(256'd0),
    .i_seq_ref_length	(8'd0),
    .i_seq_read_length	(8'd0),
    
    .i_ready			(1'd0),
    .o_valid			(valid),
    .o_alignment_score	(align_s),
    .o_column			(col),
    .o_row				(row)
);

task StartRead;
    input [4:0] addr;
    begin
        avm_read_nxt = 1;
        avm_write_nxt = 0;
        avm_address_nxt = addr;
    end
endtask
task StartWrite;
    input [4:0] addr;
    begin
        avm_read_nxt = 0;
        avm_write_nxt = 1;
        avm_address_nxt = addr;
    end
endtask

// TODO
always_comb begin
    // TODO
    case(state_r)
        S_QUERY_RX:begin
            n_nxt = n_r;
            d_nxt = d_r;
            enc_nxt = enc_r;
            dec_nxt = dec_r;
            rsa_start_nxt = rsa_start_r;
            if((!avm_waitrequest) && avm_readdata[RX_OK_BIT]) begin
                StartRead(RX_BASE);
                state_nxt = S_READ;
                bytes_counter_nxt = bytes_counter_r + 1;
            end
            else begin
                StartRead(STATUS_BASE);
                state_nxt = S_QUERY_RX;
                bytes_counter_nxt = bytes_counter_r;
            end
        end
        S_READ:begin
            dec_nxt = dec_r;
            if(!avm_waitrequest) begin
                StartRead(STATUS_BASE);
                // read the last byte of a in cycle 64
                if(bytes_counter_r == data_counter_end) begin
                    n_nxt = n_r;
                    d_nxt = d_r;
                    enc_nxt = {enc_r[247:0], avm_readdata[7:0]};
                    state_nxt = S_WAIT_CALCULATE;
                    bytes_counter_nxt = 0;
                    rsa_start_nxt = 1'b1;
                    // stop reading when calculate
                    avm_read_nxt = 0;
                end
                // read d in cycles 33~63
                else if(bytes_counter_r >= read_d_start) begin
                    // n is received, start reading d 
                    n_nxt = n_r;
                    d_nxt = {d_r[247:0], avm_readdata[7:0]};
                    enc_nxt = enc_r;
                    state_nxt = S_QUERY_RX;
                    bytes_counter_nxt = bytes_counter_r;
                    rsa_start_nxt = rsa_start_r;
                end
                // read n in cycles 1~32
                else begin
                    n_nxt = {n_r[247:0], avm_readdata[7:0]};
                    d_nxt = d_r;
                    enc_nxt = enc_r;
                    state_nxt = S_QUERY_RX;
                    bytes_counter_nxt = bytes_counter_r;
                    rsa_start_nxt = rsa_start_r;
                end
            end
            else begin
                n_nxt = n_r;
                d_nxt = d_r;
                enc_nxt = enc_r;
                state_nxt = state_r;
                bytes_counter_nxt = bytes_counter_r;
                rsa_start_nxt = rsa_start_r;
                avm_address_nxt = avm_address_r;
                avm_read_nxt = avm_read_r;
                avm_write_nxt = avm_write_r;
            end
        end
        S_WAIT_CALCULATE:begin
            n_nxt = n_r;
            d_nxt = d_r;
            enc_nxt = enc_r;
            dec_nxt = rsa_dec;
            state_nxt = rsa_finished ? S_QUERY_TX : S_WAIT_CALCULATE;
            bytes_counter_nxt = bytes_counter_r;
            rsa_start_nxt = 1'b0;
            avm_address_nxt = avm_address_r;
            avm_read_nxt = rsa_finished ? 1'b1 : avm_read_r;
            avm_write_nxt = avm_write_r;
        end
        S_QUERY_TX:begin
            n_nxt = n_r;
            d_nxt = d_r;
            enc_nxt = enc_r;
            dec_nxt = dec_r;
            rsa_start_nxt = rsa_start_r;
            if((!avm_waitrequest) && avm_readdata[TX_OK_BIT]) begin
                StartWrite(TX_BASE);
                state_nxt = S_SEND_DATA;
                bytes_counter_nxt = bytes_counter_r + 1;
            end
            else begin
                StartRead(STATUS_BASE);
                state_nxt = S_QUERY_TX;
                bytes_counter_nxt = bytes_counter_r;
            end
        end
        S_SEND_DATA:begin
            if(!avm_waitrequest) begin
                StartRead(STATUS_BASE);
                if(bytes_counter_r == write_data_end) begin
                    // all bytes of dec data are transmitted
                    n_nxt = n_r;
                    d_nxt = d_r;
                    enc_nxt = 0;
                    dec_nxt = dec_r;
                    state_nxt = S_QUERY_RX;
                    bytes_counter_nxt = 64;
                    rsa_start_nxt = 0;
                end
                else begin
                    n_nxt = n_r;
                    d_nxt = d_r;
                    enc_nxt = enc_r;
                    dec_nxt = {dec_r[247:0], dec_r[255:248]};
                    state_nxt = S_QUERY_TX;
                    bytes_counter_nxt = bytes_counter_r;
                    rsa_start_nxt = rsa_start_r;
                end
            end
            else begin
                n_nxt = n_r;
                d_nxt = d_r;
                enc_nxt = enc_r;
                dec_nxt = dec_r;
                state_nxt = state_r;
                bytes_counter_nxt = bytes_counter_r;
                rsa_start_nxt = rsa_start_r;
                avm_address_nxt = avm_address_r;
                avm_read_nxt = avm_read_r;
                avm_write_nxt = avm_write_r;
            end
        end
        default:begin
            n_nxt = n_r;
            d_nxt = d_r;
            enc_nxt = enc_r;
            dec_nxt = dec_r;
            state_nxt = state_r;
            bytes_counter_nxt = bytes_counter_r;
            rsa_start_nxt = rsa_start_r;
            avm_address_nxt = avm_address_r;
            avm_read_nxt = avm_read_r;
            avm_write_nxt = avm_write_r;
        end
    endcase
end

// TODO
always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
    	n_r <= 0;
        d_r <= 0;
        enc_r <= 0;
        dec_r <= 0;
        state_r <= S_QUERY_RX;
        bytes_counter_r <= 0;
        rsa_start_r <= 0;
        avm_address_r <= STATUS_BASE;
        avm_read_r <= 1;
        avm_write_r <= 0;

    end
	else begin
    	n_r <= n_nxt;
        d_r <= d_nxt;
        enc_r <= enc_nxt;
        dec_r <= dec_nxt;
        state_r <= state_nxt;
        bytes_counter_r <= bytes_counter_nxt;
        rsa_start_r <= rsa_start_nxt;
        avm_address_r <= avm_address_nxt;
        avm_read_r <= avm_read_nxt;
        avm_write_r <= avm_write_nxt;

    end
end

endmodule
