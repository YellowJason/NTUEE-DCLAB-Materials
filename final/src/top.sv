/************************************************************************
 * Author        : Wen Chunyang
 * Email         : 1494640955@qq.com
 * Create time   : 2018-04-08 16:56
 * Last modified : 2018-04-08 16:56
 * Filename      : top.v
 * Description   : 
 * *********************************************************************/
module  top(
        input                   CLOCK_50                ,
        //ADC
        output             VGA_CLK                 ,
        output              VGA_SYNC_N              ,
        output             VGA_BLANK_N             ,
        //VGA               
        output              VGA_HS                  ,
        output              VGA_VS                  ,
        output    [ 7: 0]   VGA_R                   ,
        output    [ 7: 0]   VGA_G                   ,
        output    [ 7: 0]   VGA_B                   
);
//=====================================================================\
// ********** Define Parameter and Internal Signals *************
//=====================================================================/
logic                            rst_n                           ; 
logic                            clk_25m                         ;
logic                            clk_65m                         ; 
logic                            clk_130m                        ; 
logic                            clk                             ; 
//======================================================================
// ***************      Main    Code    ****************
//======================================================================




pll_clk	pll_clk_inst (
        .inclk0                 (CLOCK_50               ),
        .c0                     (clk                    ),
        .c1                     (clk_25m                ),
        .c2                     (clk_65m                ),
		  .c3                     (clk_130m               ),
        .locked                 (rst_n                  )
	);


vga vga_inst(
        .clk                    (clk_25m                ),
        .rst_n                  (rst_n                  ),
        //vga
        .vga_r                  (VGA_R                  ),
        .vga_g                  (VGA_G                  ),
        .vga_b                  (VGA_B                  ),
        .vga_hs                 (VGA_HS                 ),
        .vga_vs                 (VGA_VS                 ),
        .vga_blank              (VGA_BLANK_N            ),
        .vga_sync               (VGA_SYNC_N             ),
        .vga_clk                (VGA_CLK                )
);


endmodule