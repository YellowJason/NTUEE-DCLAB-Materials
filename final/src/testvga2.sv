module vga(
    input clk,
    input rst_n,
    //vga
    output [7:0] o_vga_r,
    output [7:0] o_vga_g,
    output [7:0] o_vga_b,
    output o_vga_hs,
    output o_vga_vs,
    output o_vga_blank,
    output o_vga_sync,
    output o_vga_clk 
);

parameter H_DISP = 10'd800;
parameter V_DISP = 10'd600;
parameter H_SYNC = 10'd128;
parameter H_BACK = 10'd88;
parameter H_FRONT = 10'd40;
parameter H_TOTAL = 11'd1056;
parameter V_SYNC = 10'd4;
parameter V_BACK = 10'd23;
parameter V_FRONT = 10'd1;
parameter V_TOTAL = 10'd628;

logic [10:0] hcnt;
logic [9:0] vcnt;

assign vga_clk = ~clk;

// output buffer
logic [7:0] vga_r;
logic [7:0] vga_g;
logic [7:0] vga_b;
logic vga_hs;
logic vga_vs;
logic vga_blank;
logic vga_sync;
assign o_vga_r = vga_r;
assign o_vga_g = vga_g;
assign o_vga_b = vga_b;
assign o_vga_hs = vga_hs;
assign o_vga_vs = vga_vs;
assign o_vga_blank = vga_blank;
assign o_vga_sync = vga_sync;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        hcnt <= 0;
        vga_hs <= 1;
        vga_blank <= 1;
        vga_sync <= 0;
    end
    else begin
        hcnt <= hcnt+1;
        if (hcnt<H_SYNC) vga_hs<=0;
        else if (hcnt<H_SYNC+H_BACK) vga_hs<=1;
        else if (hcnt<H_SYNC+H_DISP+H_BACK) vga_hs<=1;
        else if (hcnt<H_SYNC+H_DISP+H_BACK+H_FRONT) vga_hs<=1;
        else hcnt<=0;
    end  
end
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        vcnt <= 0;
        vga_vs <= 1;
    end
    else begin
        if (hcnt==(H_SYNC+H_DISP+H_BACK+H_FRONT)) vcnt<=vcnt+1;
        if (vcnt<V_SYNC) vga_vs <=0;
        else if (vcnt<V_SYNC+V_BACK) vga_vs<=0;
        else if (vcnt<V_SYNC+V_DISP+V_BACK) vga_vs<=1;
        else if (vcnt<V_SYNC+V_DISP+V_BACK+V_FRONT) vga_vs<=1;
        else vcnt<=0;
    end
end

assign x = (hcnt>H_SYNC+H_BACK-1'b1)&&(hcnt<H_SYNC+H_BACK+H_DISP)?(hcnt-H_SYNC+1'b1):32'd0;
assign y = (vcnt>H_SYNC+H_BACK-1'b1)&&(vcnt<H_SYNC+H_BACK+H_DISP)?(vcnt-H_SYNC+1'b1):32'd0;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vga_r <= 0;
        vga_g <= 0;
        vga_b <= 0;
    end
    else begin
        if (x==0) begin
            vga_r<=0;
            vga_g<=0;
            vga_b<=0;
        end
        else if (x<H_DISP/3) begin
            vga_r<=8'd255;
            vga_g<=8'd255;
            vga_b<=8'd255;
        end
        else if (x<H_DISP*2/3) begin
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