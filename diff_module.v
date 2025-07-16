module diff_module #(
    parameter WINDOW_SIZE_BITS = 8,
    parameter INTERMEDIATE_DATA_WIDTH = 32,
    parameter DATA_WIDTH = 16,
    parameter MAX_TAU = 40
) (
    input clk,
    input wire [(2**WINDOW_SIZE_BITS + MAX_TAU)*DATA_WIDTH-1:0] data_in,
    input wire [5:0] tau,
    input wire reset,
    output reg ready,
    output reg [INTERMEDIATE_DATA_WIDTH-1:0] accumulator
);
    // índice en la sumatoria
    reg [WINDOW_SIZE_BITS:0] sum_index = 0;
    reg [WINDOW_SIZE_BITS:0] new_sum_index = 0;

    // flipflop registers
    reg [DATA_WIDTH-1:0] xj = 0;
    reg [DATA_WIDTH-1:0] xjtau = 0;

    reg new_ready = 0;

    reg [INTERMEDIATE_DATA_WIDTH-1:0] new_accumulator = 0;

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
    reg [2*DATA_WIDTH-1:0] diff;
    always @(*) begin
        // Init lhs ff
        new_sum_index       <= sum_index;
        new_accumulator     <= accumulator;
        new_ready           <= ready;

        if (~ready) begin
            xj = data_in[sum_index*DATA_WIDTH+:DATA_WIDTH];
            xjtau = data_in[(sum_index+tau)*DATA_WIDTH+:DATA_WIDTH];
            
            // Aca ya tengo xj y xjtau
            if (xj < xjtau) begin
                diff = xjtau - xj;
            end
            else begin
                diff = xj - xjtau;
            end

            // guardo y aumento
            new_accumulator <= accumulator + (diff*diff >> 2);
            new_sum_index <= sum_index + 1;
                
            if (sum_index == (2 ** WINDOW_SIZE_BITS) - 1) begin
                new_ready <= 1'b1;
                new_accumulator <= accumulator >> 2;
            end
        end
    end

endmodule