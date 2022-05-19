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

// SW Core --------------------------------------------
module SW_core(
    input                        clk,
    input                        rst,   

    output reg                   o_ready,
    input                        i_valid,
    input [2*128-1:0]            i_sequence_ref,     // reference seq
    input [2*128-1:0]            i_sequence_read,    // read seq
    input [$clog2(128):0]        i_seq_ref_length,   // (1-based)
    input [$clog2(128):0]        i_seq_read_length,  // (1-based)

    input                        i_ready,
    output reg                   o_valid,
    output signed [10-1:0]       o_alignment_score,
    output reg [$clog2(128)-1:0] o_column,
    output reg [$clog2(128)-1:0] o_row
);
    integer i, j, k, l;
    
    localparam  S_idle           = 4'd0,
                S_input          = 4'd1,
                S_calculate      = 4'd2,
                S_select_highest = 4'd3,
                S_done           = 4'd4;

    localparam MOST_NEGATIVE = {1'b1, {(10-1){1'b0}}};

    ///////////////////////////// main registers ////////////////////////////////
    reg [3:0]               state, state_n;
    reg [$clog2(128+128):0] counter, counter_n;
    reg [2*128-1:0]         sequence_A, sequence_A_n;
    reg [2*128-1:0]         sequence_B, sequence_B_n;
    reg [$clog2(128):0]     seq_A_length, seq_A_length_n;
    reg [$clog2(128):0]     seq_B_length, seq_B_length_n;

    reg                     sequence_B_valid[0:128-1], sequence_B_valid_n[0:128-1];
    reg [2*128-1:0]         sequence_A_shifter, sequence_A_shifter_n;

    reg signed [10-1:0]     highest_score, highest_score_n;
    reg [$clog2(128)-1:0]   column, column_n;
    reg [$clog2(128)-1:0]   row, row_n;

    reg signed [10-1:0]     row_highest_scores [0:128-1], row_highest_scores_n  [0:128-1];
    reg [$clog2(128)-1:0]   row_highest_columns[0:128-1], row_highest_columns_n [0:128-1];

    reg signed [10-1:0]     PE_score_buff [0:128-1], PE_score_buff_n [0:128-1];

    reg signed [10-1:0]     PE_align_score_d  [0:128-1], PE_align_score_d_n  [0:128-1];
    reg signed [10-1:0]     PE_insert_score_d [0:128-1], PE_insert_score_d_n [0:128-1];
    reg signed [10-1:0]     PE_delete_score_d [0:128-1], PE_delete_score_d_n [0:128-1];
    
    reg signed [10-1:0]     PE_align_score_dd [0:128-1], PE_align_score_dd_n [0:128-1];
    reg signed [10-1:0]     PE_insert_score_dd[0:128-1], PE_insert_score_dd_n[0:128-1];
    reg signed [10-1:0]     PE_delete_score_dd[0:128-1], PE_delete_score_dd_n[0:128-1];

    // output reg
    reg                   o_valid_n;
    reg [$clog2(128)-1:0] o_column_n;
    reg [$clog2(128)-1:0] o_row_n;

    assign o_alignment_score = highest_score;

    //----------------------------------------------------------------------------------------
    wire signed [10-1:0] PE_align_score [128:0];
    wire signed [10-1:0] PE_insert_score [128:0];
    wire signed [10-1:0] PE_delete_score [128:0];
    
    wire        PE_last_A_base_valid [128:0];
    wire [1:0]  PE_last_A_base       [128:0];

    genvar gv;
    generate
        for (gv=0;gv<128;gv=gv+1) begin: PEs
            if (gv==0) begin
                DP_PE_single u_PE_single(
                    ///////////////////////////////////// basics /////////////////////////////////////
                    .clk                        (clk),
                    .rst                        (rst),
                    ///////////////////////////////////// I/Os //////////////////////////////////////
                    .i_A_base_valid             ((state == S_calculate) && (counter <= seq_A_length)),
                    .i_A_base                   (sequence_A_shifter[2*128-1-:2]),

                    .i_B_base_valid             (sequence_B_valid[gv]),
                    .i_B_base                   (sequence_B[2*128-1-(2*gv)-:2]),

                    .i_align_top_score          ({(10){1'b0}}), // (0),
                    .i_insert_top_score         ({(10){1'b0}}), // (0),
                    .i_align_diagonal_score     ({(10){1'b0}}), // (0),
                    .i_insert_diagonal_score    ({(10){1'b0}}), // (0),
                    .i_delete_diagonal_score    ({(10){1'b0}}), // (0),

                    .i_align_left_score         (PE_align_score_d[gv]),
                    .i_insert_left_score        (PE_insert_score_d[gv]),
                    .i_delete_left_score        (PE_delete_score_d[gv]),

                    .o_align_score              (PE_align_score[gv]),
                    .o_insert_score             (PE_insert_score[gv]),
                    .o_delete_score             (PE_delete_score[gv]),

                    .o_the_score                (PE_score_buff_n [gv]),
                    .o_last_A_base_valid        (PE_last_A_base_valid[gv]),
                    .o_last_A_base              (PE_last_A_base[gv])
                );
            end 
            else begin
                DP_PE_single u_PE_single(
                    ///////////////////////////////////// basics /////////////////////////////////////
                    .clk                        (clk),
                    .rst                        (rst),
                    ///////////////////////////////////// I/Os //////////////////////////////////////
                    .i_A_base_valid             (PE_last_A_base_valid[gv-1]),
                    .i_A_base                   (PE_last_A_base[gv-1]),
                    .i_B_base_valid             (sequence_B_valid[gv]),
                    .i_B_base                   (sequence_B[2*128-1-(2*gv)-:2]),
                    
                    .i_align_diagonal_score     (PE_align_score_dd [gv-1]),
                    .i_align_top_score          (PE_align_score_d  [gv-1]),
                    .i_align_left_score         (PE_align_score_d  [gv]),

                    .i_insert_diagonal_score    (PE_insert_score_dd[gv-1]),
                    .i_insert_top_score         (PE_insert_score_d [gv-1]), 
                    .i_insert_left_score        (PE_insert_score_d [gv]),                  
                    
                    .i_delete_diagonal_score    (PE_delete_score_dd[gv-1]),                  
                    .i_delete_left_score        (PE_delete_score_d [gv]),

                    .o_align_score              (PE_align_score[gv]),
                    .o_insert_score             (PE_insert_score[gv]),
                    .o_delete_score             (PE_delete_score[gv]),

                    .o_the_score                (PE_score_buff_n[gv]),
                    .o_last_A_base_valid        (PE_last_A_base_valid[gv]),
                    .o_last_A_base              (PE_last_A_base[gv])
                );
            end
        end
    endgenerate

    //////////////////////////// state control ////////////////////////////
    always @(*) begin
        state_n = state;
        case(state)
            S_idle:             state_n = (i_valid) ? S_input : state;
            S_input:            state_n = S_calculate;
            S_calculate:        state_n = (counter == seq_A_length + seq_B_length - 1) ? S_select_highest : state;
            S_select_highest:   state_n = (counter == seq_B_length - 1) ? S_done : state;
            S_done:             state_n = (i_ready) ? S_idle : state;
        endcase
    end

    ///////////////////// main design ///////////////////
    always @(*) begin
        sequence_A_n                                   = sequence_A;
        sequence_B_n                                   = sequence_B;
        seq_A_length_n                                 = seq_A_length;
        seq_B_length_n                                 = seq_B_length;

        counter_n                                      = counter;
        for (i=0;i<128;i=i+1) sequence_B_valid_n[i]    = sequence_B_valid[i];
        sequence_A_shifter_n                           = sequence_A_shifter;

        highest_score_n                                = highest_score;
        column_n                                       = column;
        row_n                                          = row;
        for (i=0;i<128;i=i+1) row_highest_scores_n[i]  = row_highest_scores [i];
        for (i=0;i<128;i=i+1) row_highest_columns_n[i] = row_highest_columns[i];

        for (i=0;i<128;i=i+1) PE_align_score_d_n  [i]  = PE_align_score_d [i];
        for (i=0;i<128;i=i+1) PE_insert_score_d_n [i]  = PE_insert_score_d [i];
        for (i=0;i<128;i=i+1) PE_delete_score_d_n [i]  = PE_delete_score_d [i];

        for (i=0;i<128;i=i+1) PE_align_score_dd_n [i]  = PE_align_score_d [i];
        for (i=0;i<128;i=i+1) PE_insert_score_dd_n[i]  = PE_insert_score_d [i];
        for (i=0;i<128;i=i+1) PE_delete_score_dd_n[i]  = PE_delete_score_d [i];

    //////////////////////////////////////////// output ports ////////////////////////////////////////////
        o_ready    = 0;        
        o_valid_n  = 0;
        o_column_n = 0;
        o_row_n    = 0;

        // *** TODO
        case(state)
            S_idle: begin
                o_ready = 1'b1;
                counter_n = 9'b0;
                sequence_A_n = i_sequence_read;
                sequence_B_n = i_sequence_ref;
                seq_A_length_n = i_seq_read_length;
                seq_B_length_n = i_seq_ref_length;
            end
            S_input: begin
                o_ready = 1'b1;
                counter_n = counter + 1'b1;
                sequence_A_shifter_n = sequence_A_n;
                for (i=0;i<128;i=i+1) sequence_B_valid_n[i] = 1'b1;
            end
            S_calculate: begin
                o_ready = 1'b0;
                counter_n = counter + 1'b1;
                sequence_A_shifter_n = {sequence_A_shifter_n[2*128-3:0], 2'b00};
            end
            S_select_highest: begin
                o_ready = 1'b0;
            end
            S_done: begin
                o_ready = 1'b0;
                for (i=0;i<128;i=i+1) sequence_B_valid_n[i] = 1'b0;
            end
        endcase
    end

    /////////////////////////////// main ////////////////////////////
    always@(posedge clk or posedge rst) begin
        if (rst) begin
            state                                     <= S_idle;
            counter                                   <= 0;
            sequence_A                                <= 0;
            sequence_B                                <= 0;
            seq_A_length                              <= 0;
            seq_B_length                              <= 0;
            for (i=0;i<128;i=i+1) sequence_B_valid[i] <= 0;
            sequence_A_shifter                        <= 0;

            highest_score                             <= MOST_NEGATIVE;            
            column                                    <= 0;
            row                                       <= 0;

            for (i=0;i<128;i=i+1) row_highest_scores[i]  <= 0;
            for (i=0;i<128;i=i+1) row_highest_columns[i] <= 0;

            for (i=0;i<128;i=i+1) PE_score_buff[i]       <= 0;
            for (i=0;i<128;i=i+1) PE_align_score_d  [i]  <= 0;
            for (i=0;i<128;i=i+1) PE_insert_score_d [i]  <= 0;
            for (i=0;i<128;i=i+1) PE_delete_score_d [i]  <= 0;
            for (i=0;i<128;i=i+1) PE_align_score_dd [i]  <= 0;
            for (i=0;i<128;i=i+1) PE_insert_score_dd[i]  <= 0;
            for (i=0;i<128;i=i+1) PE_delete_score_dd[i]  <= 0;

            o_valid  <= 0;
            o_column <= 0;
            o_row    <= 0;
        end
        else begin
            state                                          <= state_n;
            counter                                        <= counter_n;
            sequence_A                                     <= sequence_A_n;
            sequence_B                                     <= sequence_B_n;
            seq_A_length                                   <= seq_A_length_n;
            seq_B_length                                   <= seq_B_length_n;
            for (i=0;i<128;i=i+1) sequence_B_valid[i]      <= sequence_B_valid_n[i];
            sequence_A_shifter                             <= sequence_A_shifter_n;
            
            highest_score                                  <= highest_score_n;
            column                                         <= column_n;
            row                                            <= row_n;

            for (i=0;i<128;i=i+1) row_highest_scores[i]    <= row_highest_scores_n [i];
            for (i=0;i<128;i=i+1) row_highest_columns[i]   <= row_highest_columns_n[i];

            for (i=0;i<128;i=i+1) PE_score_buff[i]         <= PE_score_buff_n[i];
            for (i=0;i<128;i=i+1) PE_align_score_d  [i]    <= PE_align_score_d_n   [i];
            for (i=0;i<128;i=i+1) PE_insert_score_d [i]    <= PE_insert_score_d_n  [i];
            for (i=0;i<128;i=i+1) PE_delete_score_d [i]    <= PE_delete_score_d_n  [i];
            for (i=0;i<128;i=i+1) PE_align_score_dd [i]    <= PE_align_score_dd_n  [i];
            for (i=0;i<128;i=i+1) PE_insert_score_dd[i]    <= PE_insert_score_dd_n [i];
            for (i=0;i<128;i=i+1) PE_delete_score_dd[i]    <= PE_delete_score_dd_n [i];            

            o_valid  <= o_valid_n;
            o_column <= o_column_n;
            o_row    <= o_row_n;
        end
    end

endmodule

module DP_PE_single(
    ///////////////////////////////////// basics /////////////////////////////////////
    input                    clk,
    input                    rst,

    ///////////////////////////////////// I/Os //////////////////////////////////////
    input                    i_A_base_valid,
    input                    i_B_base_valid,
    input [1:0]              i_A_base, // reference one.   Mapping: reference sequence
    input [1:0]              i_B_base, // query one.       Mapping: short-read
    
    input signed [10-1:0]    i_align_diagonal_score,
    input signed [10-1:0]    i_align_top_score,
    input signed [10-1:0]    i_align_left_score, 

    input signed [10-1:0]    i_insert_diagonal_score,
    input signed [10-1:0]    i_insert_top_score,
    input signed [10-1:0]    i_insert_left_score, // if !(i_A_base_valid && i_B_base_valid), o_insert_score = i_insert_left_score
    
    input signed [10-1:0]    i_delete_diagonal_score,
    input signed [10-1:0]    i_delete_left_score,

    output reg signed [10-1:0]   o_align_score,
    output reg signed [10-1:0]   o_insert_score,
    output reg signed [10-1:0]   o_delete_score,

    output reg signed [10-1:0]   o_the_score, // The highest score among o_align_score, o_insert_score and o_delete_score
    output reg                   o_last_A_base_valid,
    output reg [1:0]             o_last_A_base
);

// *** TODO
always_comb begin
    // o_align_score
    if (i_A_base == i_B_base) begin
        o_align_score = i_align_diagonal_score + `CONST_MATCH_SCORE;
    end
    else begin
        o_align_score = i_align_diagonal_score + `CONST_MISMATCH_SCORE;
    end
    // o_insert_score
    if ((i_align_top_score + `CONST_GAP_OPEN)<0 && (i_insert_top_score + `CONST_GAP_EXTEND)<0) begin
        o_insert_score = 0;
    end
    else if ((i_align_top_score + `CONST_GAP_OPEN) > (i_insert_top_score + `CONST_GAP_EXTEND)) begin
        o_insert_score = i_align_top_score + `CONST_GAP_OPEN;
    end
    else begin
        o_insert_score = i_insert_top_score + `CONST_GAP_EXTEND;
    end
    // o_delete_score
    if ((i_align_left_score + `CONST_GAP_OPEN)<0 && (i_delete_left_score + `CONST_GAP_EXTEND)<0) begin
        o_delete_score = 0;
    end
    else if ((i_align_left_score + `CONST_GAP_OPEN) > (i_delete_left_score + `CONST_GAP_EXTEND)) begin
        o_delete_score = i_align_left_score + `CONST_GAP_OPEN;
    end
    else begin
        o_delete_score = i_delete_left_score + `CONST_GAP_EXTEND;
    end
    // o_the_score
    if (o_align_score<0 && o_insert_score<0 && o_delete_score<0) begin
        o_the_score = 0;
    end
    else if (o_align_score>=o_insert_score && o_align_score>=o_delete_score) begin
        o_the_score = o_align_score;
    end
    else if (o_insert_score>=o_align_score && o_insert_score>=o_delete_score) begin
        o_the_score = o_insert_score;
    end
    else begin
        o_the_score = o_delete_score;
    end
end

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        o_last_A_base_valid <= 0;
        o_last_A_base       <= 0;
    end else begin
        o_last_A_base_valid <= i_A_base_valid;
        o_last_A_base       <= i_A_base;
    end
end

endmodule
