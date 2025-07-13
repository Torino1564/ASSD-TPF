module display_module
#(parameter WORDS = 4)
(
    input wire [4*WORDS-1:0] VALUE_BCD,
    input wire internal_clock,
    output reg VALUE_SIGNAL,
    output reg ENABLE_SIGNAL,
    output reg BOARD_CLOCK_SIGNAL,
    output reg DATA_CLOCK_SIGNAL
);
    // Define clocks
    // Display Clock
    reg [10:0] freq_counter_i;
    parameter CLK_RST = 400;
     always @(posedge internal_clock) begin
	    freq_counter_i <= freq_counter_i + 1'b1;
        if (freq_counter_i > CLK_RST) begin
            freq_counter_i <= 0;
            BOARD_CLOCK_SIGNAL <= !BOARD_CLOCK_SIGNAL;
        end
    end

    // Serial Clock
    reg [20:0] freq_counter_2;
    parameter DATA_CLK_RST = 2000;
     always @(posedge internal_clock) begin
	    freq_counter_2 <= freq_counter_2 + 1'b1;
        if (freq_counter_2 > DATA_CLK_RST) begin
            freq_counter_2 <= 0;
            DATA_CLOCK_SIGNAL <= !DATA_CLOCK_SIGNAL;
        end
    end

    wire [3:0] algo;
    wire busy,fin, RST;
    reg en = 1'b1;
    
    reg [7:0] counter = 1'b0;
    wire cnt_enable;
    reg clk_prev;
    always @(posedge internal_clock) begin 
        clk_prev <= DATA_CLOCK_SIGNAL;
    end
    assign cnt_enable = DATA_CLOCK_SIGNAL & (~clk_prev);

    always @(posedge internal_clock) begin
        if (cnt_enable == 1'd1) begin
            if(counter < 5'd16) begin
                ENABLE_SIGNAL <= 1'b1;
                VALUE_SIGNAL <= VALUE_BCD[(3 - counter%4) + (counter/4)*4];
                counter <= counter + 1;
            end
            else if (counter < 6'd32) begin
                VALUE_SIGNAL <= 1'b0;
                ENABLE_SIGNAL <= 1'b0;
                counter <= counter + 1;
            end
            else 
                counter <= 0;
        end
    end
endmodule