module Keyboard2(
    input i_clk,
    input i_rst_n,
    // PS2 input signal
    input i_data,
    input i_ps2_clk,
    // output signal
    output [7:0] o_data,
    output [7:0] o_data_down,
    output o_finish
);

// keys we want to detect
parameter up = 8'h75;
parameter down = 8'h72;
parameter right = 8'h74;
parameter left = 8'h6b;

logic [7:0] data_pre, data_curr;
logic [3:0] counter;
logic flag;

assign o_data = data_pre;
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
assign update = (data_curr==up) || (data_curr==down) || (data_curr==right) || (data_curr==left);

always_ff @(posedge flag) begin
    if (update) data_pre <= data_curr;
    else        data_pre <= data_pre;
end

endmodule