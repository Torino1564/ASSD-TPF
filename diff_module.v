module diff_module #(
    parameter WINDOW_SIZE_BITS = 8,
    parameter DATA_WIDTH = 16,
    parameter MAX_TAU = 40 // representa 20ms
) (
    input clk,
    input wire [DATA_WIDTH*((2**WINDOW_SIZE_BITS) + MAX_TAU)-1:0] data_in,
    input wire[5:0] tau,
    input wire reset,
    output reg ready,
    output reg [38:0] accumulator
);
    // índice en la sumatoria
    reg [WINDOW_SIZE_BITS-1:0] sum_index = 0;
    reg [WINDOW_SIZE_BITS-1:0] new_sum_index = 0;

    // flipflop registers
    reg [DATA_WIDTH-1:0] xj = 0;
    reg [DATA_WIDTH-1:0] xjtau = 0;

    reg new_ready = 0;

    reg [38:0] new_accumulator = 0;

    always @(posedge clk) begin
        if (reset) begin
            sum_index       <= 0;
            accumulator     <= 0;
            ready           <= 0;
            xj              <= 0;
            xjtau           <= 0;
        end
        else begin
            sum_index       <= new_sum_index;
            accumulator     <= new_accumulator;
            ready           <= new_ready;
        end
    end
    reg [DATA_WIDTH-1:0] diff;
    always @(*) begin
        // Init lhs ff
        new_sum_index       = sum_index;
        new_accumulator     = accumulator;
        new_ready           = ready;

        if (~ready) begin
            xj = data_in[DATA_WIDTH*sum_index+:DATA_WIDTH];
            xjtau = data_in[DATA_WIDTH*(sum_index+tau)+:DATA_WIDTH];
            
            // Aca ya tengo xj y xjtau
            if (xj < xjtau) begin
                diff = xjtau - xj;
            end
            else begin
                diff = xj - xjtau;
            end

            // guardo y aumento
            new_accumulator = accumulator + diff*diff;
            new_sum_index = sum_index + 1;
                
            if (sum_index == (2 ** WINDOW_SIZE_BITS) - 1) begin
                new_ready = 1'b1;
            end
        end
    end

endmodule