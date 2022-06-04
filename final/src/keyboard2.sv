module Keyboard2(
    input i_rst_n,
    // PS2 input signal
    input i_data,
    input i_ps2_clk,
    // output signal
    output [7:0] o_data,
    output [7:0] o_data_2
    // output [7:0] o_data_down,
    // output o_finish
);

// keys we want to detect
parameter esc = 8'h76;

parameter up = 8'h75;
parameter down = 8'h72;
parameter right = 8'h74;
parameter left = 8'h6b;
parameter enter = 8'h5a;
parameter space = 8'h29;

// key for player 2
parameter w = 8'h1d;
parameter a = 8'h1c;
parameter s = 8'h1b;
parameter d = 8'h23;
parameter shift = 8'h12;
parameter ctrl = 8'h14;

logic [7:0] data_pre, data_pre_2, data_curr;
logic [3:0] counter;
logic flag;
logic keyup;

assign o_data = data_pre;
assign o_data_2 = data_pre_2;
assign o_data_down = data_curr;
assign o_finish = flag;

always_ff @(negedge i_ps2_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        data_curr <= 8'b0;
        counter <= 4'b0;
        flag <= 1'b0;
    end
    else begin
        case(counter)
            0:; //first bit
            1:data_curr[0] <= i_data;
            2:data_curr[1] <= i_data;
            3:data_curr[2] <= i_data;
            4:data_curr[3] <= i_data;
            5:data_curr[4] <= i_data;
            6:data_curr[5] <= i_data;
            7:data_curr[6] <= i_data;
            8:data_curr[7] <= i_data;
            9:flag <= 1'b1;     //Parity bit
            10:flag <= 1'b0;    //Ending bit
            default:;
        endcase
        if (counter < 10) counter <= counter+1;
        else              counter <= 0;
    end
end

logic update;
assign update = (data_curr==up) || (data_curr==down) || (data_curr==right) || (data_curr==left) || 
                (data_curr==enter) || (data_curr==space) || (data_curr==esc);
logic update_2;
assign update_2 = (data_curr==w) || (data_curr==a) || (data_curr==s) || (data_curr==d) || 
                  (data_curr==shift) || (data_curr==ctrl) || (data_curr==esc);

always_ff @(posedge flag or negedge i_rst_n) begin
    if (!i_rst_n) begin
        keyup <= 1'b0;
        data_pre <= 8'b0;
        data_pre_2 <= 8'b0;
    end
    else begin
        // receive f0, ignore next data
        if (data_curr==8'hf0) keyup <= 1'b1;
        else                  keyup <= 1'b0;
        // update output
        if (keyup) begin
            if (data_curr == data_pre) data_pre <= 8'b0;
            else data_pre <= data_pre;
            if (data_curr == data_pre_2) data_pre_2 <= 8'b0;
            else data_pre_2 <= data_pre_2;
        end
        else begin
            if (update) data_pre <= data_curr;
            else        data_pre <= data_pre;
            if (update_2) data_pre_2 <= data_curr;
            else        data_pre_2 <= data_pre_2;
        end
    end
end

endmodule