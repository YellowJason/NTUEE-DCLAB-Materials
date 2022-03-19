module Rsa256Wrapper (
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
localparam S_GET_KEY = 3'b001;
localparam S_GET_DATA = 3'b010;
localparam S_WAIT_CALCULATE = 3'b011;
localparam S_QUERY_TX = 3'b100;
localparam S_SEND_DATA = 3'b101;

logic [255:0] n_r, n_nxt, d_r, d_nxt, enc_r, enc_nxt, dec_r, dec_nxt;
logic [2:0] state_r, state_nxt;
logic [6:0] bytes_counter_r, bytes_counter_nxt;
logic [4:0] avm_address_r, avm_address_nxt;
logic avm_read_r, avm_read_nxt, avm_write_r, avm_write_nxt;

logic rsa_start_r, rsa_start_nxt;
logic rsa_finished;
logic [255:0] rsa_dec;

parameter data_counter_end = 7'b1011111 ; //32
parameter key_n_counter_end = 7'b1011111;
parameter key_nd_counter_end = 7'b1111111 ; //32*2
assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
assign avm_writedata = dec_r[247-:8];

Rsa256Core rsa256_core(
    .i_clk(avm_clk),
    .i_rst(avm_rst),
    .i_start(rsa_start_r),
    .i_a(enc_r),
    .i_d(d_r),
    .i_n(n_r),
    .o_a_pow_d(rsa_dec),
    .o_finished(rsa_finished)
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

always_comb begin
    // TODO
    case(state_r)
        S_QUERY_RX:begin
            StartRead(STATUS_BASE);
            if(!avm_waitrequest) begin
                if(avm_readdata[RX_OK_BIT]) begin
                    StartRead(RX_BASE);
                    state_nxt = S_GET_KEY;
                end
                else begin
                    state_nxt = S_QUERY_RX;
                end
            end
            else begin
                state_nxt = S_QUERY_RX;
            end
        end
        S_GET_KEY:begin
            rsa_start_nxt = 0;
            enc_nxt = enc_r;
            dec_nxt = dec_r;
            avm_address_nxt = RX_BASE;
            if(bytes_counter_r == data_counter_end) begin
                //keys all input
                state_nxt = S_GET_DATA;
                bytes_counter_nxt = 7'd63;
            end
            else if(bytes_counter_r == key_n_counter_end) begin
                state_nxt = S_GET_KEY;
                d_nxt[255:0] = {d_r[247:0], avm_readdata[7:0]};
                bytes_counter_nxt = bytes_counter_r + 1;
            end
            else begin      //assume read n then read d
                state_nxt = S_GET_KEY;
                n_nxt[255:0] = {n_r[247:0], avm_readdata[7:0]};
                bytes_counter_nxt = bytes_counter_r + 1;
            end
        end
        S_GET_DATA:begin
            d_nxt = d_r;
            dec_nxt = dec_r;
            avm_address_nxt = avm_address_r;
            if(bytes_counter_r == data_counter_end) begin
                //secret dataall input
                state_nxt = S_WAIT_CALCULATE;
                rsa_start_nxt = 1'b1;
                bytes_counter_nxt = 7'd63;
            end
            else begin
                state_nxt = S_GET_DATA;
                enc_nxt[255:0] = {enc_r[247:0], avm_readdata[7:0]};
                rsa_start_nxt = 0;
                bytes_counter_nxt = bytes_counter_r + 1;
            end
        end
        S_WAIT_CALCULATE:begin
            dec_nxt = dec_r;
            rsa_start_nxt = 0;
            enc_nxt = enc_r;
            d_nxt = d_r;
            state_nxt = rsa_finished ? S_QUERY_TX : S_WAIT_CALCULATE;
        end
        S_QUERY_TX:begin
            if(avm_readdata[TX_OK_BIT]) begin
                state_nxt = S_SEND_DATA;
                avm_address_nxt = TX_BASE;
            end
            else begin
                state_nxt = S_QUERY_TX;
                avm_address_nxt = STATUS_BASE;
            end
        end
        S_SEND_DATA:begin
            rsa_start_nxt = 0;
            enc_nxt = enc_r;
            d_nxt = d_r;
            if(bytes_counter_r == data_counter_end) begin
                //decode datas all input
                state_nxt = S_GET_KEY;
                bytes_counter_nxt = 7'd63;
            end
            else begin
                state_nxt = S_SEND_DATA;
                dec_nxt[255:0] = {dec_r[247:0], avm_writedata[7:0]};
                bytes_counter_nxt = bytes_counter_r + 1;
            end
        end
    endcase

end

always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        n_r <= 0;
        d_r <= 0;
        enc_r <= 0;
        dec_r <= 0;
        avm_address_r <= STATUS_BASE;
        avm_read_r <= 1;
        avm_write_r <= 0;
        state_r <= S_QUERY_RX;
        bytes_counter_r <= 63;
        rsa_start_r <= 0;
    end else begin
        n_r <= n_nxt;
        d_r <= d_nxt;
        enc_r <= enc_nxt;
        dec_r <= dec_nxt;
        avm_address_r <= avm_address_nxt;
        avm_read_r <= avm_read_nxt;
        avm_write_r <= avm_write_nxt;
        state_r <= state_nxt;
        bytes_counter_r <= bytes_counter_nxt;
        rsa_start_r <= rsa_start_nxt;
    end
end

endmodule
