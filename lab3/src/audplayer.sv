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
    inout i_daclrck,
    input i_en,     // enable AudPlayer only when playing audio, work with AudDSP
    input [15:0] i_dac_data,        //dac_data
    output o_aud_dacdat
);

localparam S_IDLE = 0;
localparam S_PLAY = 1;
localparam S_WAIT = 2;

logic [1:0] state, state_nxt;
logic [15:0] aud_data, aud_data_nxt;
logic [3:0] data_cnt, data_cnt_nxt;
logic lrc, lrc_nxt;

assign o_aud_dacdat = aud_data[15];

always_comb begin
    case(state)
        S_IDLE: begin
            lrc_nxt = i_daclrck;            
            data_cnt_nxt = data_cnt;        
            if (i_en && (!lrc)) begin
                aud_data_nxt = i_dac_data;  
                state_nxt = S_PLAY;         
            end
            else begin
                aud_data_nxt = aud_data;    
                state_nxt = S_IDLE;         
            end
        end

        S_PLAY: begin
            lrc_nxt = i_daclrck;            
            aud_data_nxt = aud_data << 1;   
             
            if (data_cnt == 15) begin
                data_cnt_nxt = 4'b0;        
                state_nxt = S_WAIT;         
            end
            else begin
                data_cnt_nxt = data_cnt + 1'b1;    
                state_nxt = S_PLAY;         
            end
        end

        S_WAIT: begin
            aud_data_nxt = aud_data;        
            data_cnt_nxt = data_cnt;        
            lrc_nxt = i_daclrck;            
            if(lrc) begin
                state_nxt = S_IDLE;         
            end
            else begin
                state_nxt = S_WAIT;         
            end
        end
        default:begin
            aud_data_nxt = aud_data;
            data_cnt_nxt = data_cnt
            lrc_nxt      = lrc;
            state_nxt    = state;
        end
    endcase
end

always_ff @(negedge i_bclk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        state    <= S_IDLE;
        data_cnt <= 3'b0;
        aud_data <= 16'b0;
        lrc      <= 1'b0;
    end
    else begin
        state    <= state_nxt;
        aud_data <= aud_data_nxt;
        data_cnt <= data_cnt_nxt;
        lrc      <= lrc_nxt;
    end
end

endmodule