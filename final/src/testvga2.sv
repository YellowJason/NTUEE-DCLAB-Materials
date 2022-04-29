module vga(
    input clk,              // 25MHz
    input rst_n,
    //vga
    output [7:0] o_vga_r,
    output [7:0] o_vga_g,
    output [7:0] o_vga_b,
    output o_vga_hs,        //行同步訊號
    output o_vga_vs,        //列同步訊號
    output o_vga_blank,
    output o_vga_sync,
    output o_vga_clk        // ~clk
);

parameter H_SYNC = 10'd96;      //行同步信號週期長
parameter H_BACK = 10'd48;      //行同步後沿信號週期長
parameter H_DISP = 10'd640;     //顯示行數
parameter H_FRONT = 10'd16;     //行同步前沿信號週期長
parameter H_TOTAL = 10'd800;    //行總週期長耗時

parameter V_SYNC = 10'd2;       //列同步信號週期長
parameter V_BACK = 10'd33;      //列同步後沿信號週期長
parameter V_DISP = 10'd480;     //顯示列數
parameter V_FRONT = 10'd10;     //列同步前沿信號週期長
parameter V_TOTAL = 10'd525;    //列總週期長耗時

logic [9:0] h_counter, h_counter_nxt;
logic [9:0] v_counter, v_counter_nxt;

assign o_vga_blank = ~((h_counter < H_SYNC + H_BACK) || (h_counter > H_SYNC + H_BACK + H_DISP) ||
                       (v_counter < V_SYNC + V_BACK) || (v_counter < V_SYNC + V_BACK + V_DISP));
assign o_vga_clk = ~clk;

// output buffer
logic [7:0] vga_r;
logic [7:0] vga_g;
logic [7:0] vga_b;
logic vga_hs;
logic vga_vs;
logic vga_sync;
assign o_vga_r = vga_r;
assign o_vga_g = vga_g;
assign o_vga_b = vga_b;
assign o_vga_hs = vga_hs;
assign o_vga_vs = vga_vs;
assign o_vga_sync = vga_sync;

// horizontal
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        h_counter <= 0;
        vga_hs <= 0;
        vga_sync <= 0;
    end
    else begin
        h_counter <= h_counter + 1;
        if (h_counter < H_SYNC-1) vga_hs <= 0;
        else if (h_counter < H_TOTAL-1) vga_hs <= 1;
        else h_counter<=0;
    end  
end

// vertical
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        v_counter <= 0;
        vga_vs <= 0;
    end
    else begin
        if (h_counter == H_TOTAL-1) v_counter <= v_counter + 1;
        if (v_counter < V_SYNC+V_BACK) vga_vs <= 0;
        else if (v_counter < V_TOTAL) vga_vs <= 1;
        else v_counter <= 0;
    end
end

// current display coordinate
logic [9:0] x, y;
assign x = (h_counter>H_SYNC+H_BACK-1)&&(h_counter<H_SYNC+H_BACK+H_DISP) ? (h_counter-H_SYNC-H_BACK+1) : 32'd0;
assign y = (v_counter>H_SYNC+H_BACK-1)&&(v_counter<H_SYNC+H_BACK+H_DISP) ? (v_counter-H_SYNC-H_BACK+1) : 32'd0;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vga_r <= 0;
        vga_g <= 0;
        vga_b <= 0;
    end
    else begin
        if (x == 0) begin
            vga_r<=0;
            vga_g<=0;
            vga_b<=0;
        end
        else if (x < H_DISP/3) begin
            vga_r<=8'd255;
            vga_g<=8'd255;
            vga_b<=8'd255;
        end
        else if (x < H_DISP*2/3) begin
            vga_r<=8'd0;
            vga_g<=8'd255;
            vga_b<=8'd255;
        end
        else  begin
            vga_r<=8'd0;
            vga_g<=8'd255;
            vga_b<=8'd0;
        end
    end
end

endmodule