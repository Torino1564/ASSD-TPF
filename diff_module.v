module diff_module #(
    parameter WINDOW_SIZE_BITS = 8,
    parameter DATA_WIDTH = 16,
    parameter MAX_TAU = 40 // representa 20ms
) (
    input clk,
    output reg [15:0] address,
    input wire [15:0] initial_address,
    input wire [DATA_WIDTH-1:0] data_out,
    input wire[5:0] tau,
    input wire reset,
    output reg ready,
    output reg [38:0] accumulator
);
    // índice en la sumatoria
    reg [WINDOW_SIZE_BITS-1:0] sum_index = 0;
    reg [WINDOW_SIZE_BITS-1:0] new_sum_index = 0;

    // flipflop registers
    reg requested_xj = 0;
    reg requested_xjtau = 0;
    reg fetched_xj = 0;
    reg fetched_xjtau = 0;
    reg waiting_xj = 0;
    reg waiting_xjtau = 0;
    reg [DATA_WIDTH-1:0] xj = 0;
    reg [DATA_WIDTH-1:0] xjtau = 0;

    reg [15:0] new_address = 0;
    reg new_ready = 0;
    reg new_requested_xj = 0;
    reg new_fetched_xj = 0;
    reg new_requested_xjtau = 0;
    reg new_fetched_xjtau = 0;
    reg new_waiting_xj = 0;
    reg new_waiting_xjtau = 0;
    reg [DATA_WIDTH-1:0] new_xj = 0;
    reg [DATA_WIDTH-1:0] new_xjtau = 0;

    reg [38:0] new_accumulator = 0;

    always @(posedge clk) begin
        if (reset) begin
            sum_index       <= 0;
            requested_xj    <= 0;
            requested_xjtau <= 0;
            fetched_xj      <= 0;
            fetched_xjtau   <= 0;
            accumulator     <= 0;
            ready           <= 0;
            xj              <= 0;
            xjtau           <= 0;
            waiting_xj      <= 0;
            waiting_xjtau   <= 0;
        end
        else begin
            sum_index       <= new_sum_index;
            requested_xj    <= new_requested_xj;
            requested_xjtau <= new_requested_xjtau;
            fetched_xj      <= new_fetched_xj;
            fetched_xjtau   <= new_fetched_xjtau;
            accumulator     <= new_accumulator;
            address         <= new_address;
            ready           <= new_ready;
            xj              <= new_xj;
            xjtau           <= new_xjtau;
            waiting_xj      <= new_waiting_xj;
            waiting_xjtau   <= new_waiting_xjtau;
        end
    end

    always @(*) begin
        // Init lhs ff
        new_sum_index       = sum_index;
        new_requested_xj    = requested_xj;
        new_requested_xjtau = requested_xjtau;
        new_fetched_xj      = fetched_xj;
        new_fetched_xjtau   = fetched_xjtau;
        new_accumulator     = accumulator;
        new_address         = address;
        new_ready           = ready;
        new_waiting_xj      = waiting_xj;
        new_waiting_xjtau   = waiting_xjtau;

        if (~ready) begin
            if (!requested_xj) begin
                new_address = initial_address + sum_index;
                new_requested_xj = 1'b1;
            end
            else if (requested_xj && !waiting_xj) begin
                new_waiting_xj = 1'b1;
            end
            else if (waiting_xj && !fetched_xj) begin
                new_xj = data_out;
                new_fetched_xj = 1'b1;
            end
            else if (!requested_xjtau) begin
                new_address = initial_address + sum_index + tau;
                new_requested_xjtau = 1'b1;
            end
            else if (requested_xjtau && !waiting_xjtau) begin
                new_waiting_xjtau = 1'b1;
            end
            else if (waiting_xjtau && !fetched_xjtau) begin
                new_xjtau = data_out;
                new_fetched_xjtau = 1'b1;
            end
            // Aca ya tengo xj y xjtau
            else if (fetched_xjtau) begin
                if (xj < xjtau) begin
                    new_accumulator = accumulator + ((xjtau - xj) * (xjtau - xj));
                end
                else begin
                    new_accumulator = accumulator + ((xj - xjtau) * (xj - xjtau));
                end

                // aumento y reseteo
                new_sum_index = sum_index + 1;
                new_requested_xj = 0;
                new_requested_xjtau = 0;
                new_fetched_xj = 0;
                new_fetched_xjtau = 0;
                new_waiting_xj = 0;
                new_waiting_xjtau = 0;
            end
            if (sum_index == (2 ** WINDOW_SIZE_BITS) - 1) begin
                new_ready = 1'b1;
                new_xj = 0;
                new_xjtau = 0;
            end
        end
    end

endmodule