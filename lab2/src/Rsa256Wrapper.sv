module Rsa256Wrapper (
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,   //這啥
    output        avm_read,     //這啥
    input  [31:0] avm_readdata, //[7:0]一次讀8bit為啥事32bit
    output        avm_write,   //這啥
    output [31:0] avm_writedata,    //[7:0]一次寫8bit為啥事32bit
    input         avm_waitrequest   //這啥
);
// 以下還沒用到
localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

// Feel free to design your own FSM!
localparam S_GET_KEY = 0;
localparam S_GET_DATA = 1;
localparam S_WAIT_CALCULATE = 2;
localparam S_SEND_DATA = 3;

logic [255:0] n_r, n_nxt, d_r, d_nxt, enc_r, enc_nxt, dec_r, dec_nxt;
logic [1:0] state_r, state_nxt;
logic [6:0] bytes_counter_r, bytes_counter_nxt;
logic [4:0] avm_address_r, avm_address_nxt;
logic avm_read_r, avm_read_nxt, avm_write_r, avm_write_nxt;

logic rsa_start_r, rsa_start_nxt;
logic rsa_finished;
logic [255:0] rsa_dec;

parameter data_counter_end = 7'b0011111  //32次
parameter key_n_counter_end = 7'b0011111
parameter key_nd_counter_end = 7'b0111111  //兩次32次
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
        S_GET_KEY:begin
            
            if(bytes_counter == data_counter_end) begin
                //此時key全部輸入完畢，要傳到core讓core算
                state_nxt = S_WAIT_CALCULATE;
                bytes_counter_nxt = 7'b0000000;
            end
            else if(bytes_counter == key_n_counter_end) begin
                d_nxt[255:0] = {d_r[247:0], avm_readdata[7:0]};
                bytes_counter_nxt = bytes_counter + 1;
            end
            else begin      //假設先讀n再讀d
                n_nxt[255:0] = {n_r[247:0], avm_readdata[7:0]};
                bytes_counter_nxt = bytes_counter + 1;
            end
        end
        S_GET_DATA:begin
            
            if(bytes_counter == data_counter_end) begin
                //此時秘密資料全部輸入完畢，要傳到core讓core算
                state_nxt = S_WAIT_CALCULATE;
                bytes_counter_nxt = 7'b0000000;
            end
            else begin
                enc_nxt[255:0] = {enc_r[247:0], avm_readdata[7:0]};
                bytes_counter_nxt = bytes_counter + 1;
            end
        end
        S_WAIT_CALCULATE:begin
        end
        S_SEND_DATA:begin
            if(bytes_counter == data_counter_end) begin
                //此時解密資料全部輸入完畢
                state_nxt = S_GET_KEY;
                bytes_counter_nxt = 7'b0000000;
            end
            else begin
                dec_nxt[255:0] = {dec_r[247:0], writedata[7:0]};
                bytes_counter_nxt = bytes_counter + 1;
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
        state_r <= S_GET_KEY;
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
