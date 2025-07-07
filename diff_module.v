module diff_module #(
    parameter WINDOW_SIZE_BITS = 8,
    parameter DATA_WIDTH = 16,
    parameter MAX_TAU = 40 // representa 20ms
) (
    output reg [15:0] address,
    input wire [15:0] initial_address,
    input wire [DATA_WIDTH-1:0] data_out,
    input wire[5:0] tau,
    input wire reset,
    output reg ready
);
    // índice en la sumatoria
    reg [WINDOW_SIZE_BITS-1:0] sum_index = 0;

    // xj listo?
    reg requested_xj = 0;
    reg fetched_xj = 0;
    reg requested_xjtau = 0;
    reg fetched_xjtau = 0;
    reg [DATA_WIDTH-1:0] xj = 0;
    reg [DATA_WIDTH-1:0] xjtau = 0;

    reg [38:0] acumulator = 0;

    if @(posedge clk) begin
        if (reset) begin
            sum_index <= 0;
            requested_xj <= 0;
            requested_xjtau <= 0;
            fetched_xj <= 0;
            fetched_xjtau <= 0;
            acumulator <= 0;
        end
    end

    always @(posedge clk) begin
        if (!requested_xj) begin
            address <= initial_address + sum_index;
            requested_xj <= 1'b1;
        end
        else if (requested_xj && !fetched_xj) begin
            xj <= data_out;
            fetched_xj <= 1'b1;
        end
        else if (!requested_xjtau) begin
            address <= initial_address + sum_index + tau;
            requested_xjtau <= 1'b1;
        end
        else if (requested_xjtau && !fetched_xjtau) begin
            xjtau <= data_out;
            fetched_xjtau <= 1'b1;
        end
        // Aca ya tengo xj y xjtau
        else begin
            if (xj < xjtau) begin
                acumulator <= acumulator + ((xjtau - xj) * (xjtau - xj));
            end
            else begin
                acumulator <= acumulator + ((xj - xjtau) * (xj - xjtau));
            end

            // aumento y reseteo
            sum_index <= sum_index + 1;
            requested_xj <= 0;
            requested_xjtau <= 0;
            fetched_xj <= 0;
            fetched_xjtau <= 0;
        end
        if (sum_index == (2 ** WINDOW_SIZE_BITS) - 1) begin
            data_ready <= 1'b1;
        end
    end

endmodule