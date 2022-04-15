module AudDSP(
    input i_rst_n,
    input i_clk,
    input i_start,
    input i_pause,
    input i_stop,
    input [2:0] i_speed,    // 0 -> 1*speed, 7 -> 8*speed
    input [1:0] mode,       // 4 mode
    input i_daclrck,
    input [19:0] i_last_mem,
    input [15:0] i_sram_data,
    output [15:0] o_dac_data,
    output [19:0] o_sram_addr
);

// 4 playing mode
parameter NORM  = 2'b00;
parameter FAST  = 2'b10;
parameter SLOW0 = 2'b01;
parameter SLOW1 = 2'b11;

// 5 states
parameter S_IDLE     = 3'b000;
parameter S_FETCH0   = 3'b001;  // fetch current data
parameter S_FETCH1   = 3'b010;  // fetch next data
parameter S_CALC     = 3'b011;  // calculate dac_data according to speed
parameter S_WAIT_LRC = 3'b100;  // waiting posedge daclrck, then back to FETCH0 (didn't use)
parameter S_PAUS     = 3'b101;

logic [2:0] state, state_nxt;

// daclrck
logic daclrck, daclrck_nxt;
assign daclrck_nxt = i_daclrck;

// current & next data (for slow play)
logic [15:0] data_current, data_current_nxt;
logic [15:0] data_next, data_next_nxt;

// slow counter
logic [2:0] slow_counter, slow_counter_nxt;

// output buffer
logic [19:0] sram_addr, sram_addr_nxt;
logic [15:0] dac_data, dac_data_nxt;    // update when negedge daclrck
assign o_sram_addr = sram_addr;
assign o_dac_data = dac_data;

always_comb begin
    case(state)
        S_IDLE: begin
            if (i_start) begin
                state_nxt = S_FETCH0;
            end
            else begin
                state_nxt = S_IDLE;
            end
            sram_addr_nxt = 20'b0;
            data_current_nxt = 16'b0;
            data_next_nxt = 16'b0;
            dac_data_nxt = 16'b0;
            slow_counter_nxt = 3'b0;
        end
        S_FETCH0: begin
            state_nxt = S_FETCH1;
            // different mode, only slow need data_next
            case(mode)
                NORM:  sram_addr_nxt = sram_addr;
                FAST:  sram_addr_nxt = sram_addr;
                SLOW0: sram_addr_nxt = sram_addr + 1;
                SLOW1: sram_addr_nxt = sram_addr + 1;
            endcase
            // fetch data_current
            data_current_nxt = i_sram_data;
            data_next_nxt = data_next;
            dac_data_nxt = dac_data;
            slow_counter_nxt = slow_counter;
        end
        S_FETCH1: begin
            state_nxt = S_CALC;
            // different mode, only slow need data_next
            case(mode)
                NORM: begin 
                    sram_addr_nxt = sram_addr + 1;
                end
                FAST: begin 
                    sram_addr_nxt = sram_addr + i_speed + 1;
                end
                SLOW0: begin
                    if (slow_counter == i_speed) begin
                        sram_addr_nxt = sram_addr;
                    end
                    else begin
                        sram_addr_nxt = sram_addr - 1;
                    end
                end
                SLOW1: begin
                    if (slow_counter == i_speed) begin
                        sram_addr_nxt = sram_addr;
                    end
                    else begin
                        sram_addr_nxt = sram_addr - 1;
                    end
                end
            endcase
            data_current_nxt = data_current;
            // fetch data_next
            data_next_nxt = i_sram_data;
            dac_data_nxt = dac_data;
            slow_counter_nxt = slow_counter;
        end
        S_CALC: begin
            // hold until next negedge daclrck
            if ((daclrck==1) && (daclrck_nxt==0))         state_nxt = S_FETCH0;
            else if (i_pause)                             state_nxt = S_PAUS;
            else if (i_stop || (sram_addr >= i_last_mem)) state_nxt = S_IDLE;
            else                                          state_nxt = S_CALC;
            case(mode)
                NORM:  dac_data_nxt = data_current;
                FAST:  dac_data_nxt = data_current;
                SLOW0: dac_data_nxt = data_current;
                SLOW1: dac_data_nxt =
                       ($signed(data_current)*(i_speed+1-slow_counter) + $signed(data_next)*(slow_counter)) / (i_speed+1);
            endcase
            sram_addr_nxt = sram_addr;
            data_current_nxt = data_current;
            data_next_nxt = data_next;
            if (slow_counter == i_speed) begin
                slow_counter_nxt = 3'b0;
            end
            else begin
                slow_counter_nxt = slow_counter + 1;
            end
        end
        S_PAUS: begin
            if (i_start)     state_nxt = S_CALC;
            else if (i_stop) state_nxt = S_IDLE;
            else             state_nxt = S_PAUS;
            sram_addr_nxt = sram_addr;
            data_current_nxt = data_current;
            data_next_nxt = data_next;
            dac_data_nxt = 16'b0;
            slow_counter_nxt = slow_counter;
        end
        default: begin
            state_nxt = state;
            sram_addr_nxt = sram_addr;
            data_current_nxt = data_current;
            data_next_nxt = data_next;
            dac_data_nxt = dac_data;
            slow_counter_nxt = slow_counter;
        end
    endcase
end

always_ff @(negedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state <= S_IDLE;
        daclrck <= daclrck_nxt;
        sram_addr <= 20'b0;
        data_current<= 16'b0;
        data_next <= 16'b0;
        
    end
    else begin
        state <= state_nxt;
        daclrck <= daclrck_nxt;
        sram_addr <= sram_addr_nxt;
        data_current<= data_current_nxt;
        data_next <= data_next_nxt;
    end
end

// update dac_data when negedge daclrc
always_ff @(negedge i_daclrck or negedge i_rst_n) begin
    if (!i_rst_n) begin
        dac_data <= 16'b0;
        slow_counter <= 3'b0;
    end
    else begin 
        dac_data <= dac_data_nxt;
        slow_counter <= slow_counter_nxt;
    end
end

endmodule