module modiff_module
#(
    parameter DATA_WIDTH = 8,
    parameter INTERMEDIATE_DATA_WIDTH = 64,
    parameter WINDOW_SIZE_BITS = 8,
    parameter MAX_TAU = 40
) (
    input wire clk,
    input wire reset,
    input wire [DATA_WIDTH-1:0] data [2**WINDOW_SIZE_BITS + MAX_TAU],
    output reg ready,
    output reg [INTERMEDIATE_DATA_WIDTH-1:0] results [MAX_TAU],
    output reg [INTERMEDIATE_DATA_WIDTH-1:0] average
);

wire [INTERMEDIATE_DATA_WIDTH-1:0] diff_results [MAX_TAU];
wire diff_ready;
reg [MAX_TAU-1:0] diff_reset = 0;

diff_module #(.DATA_WIDTH(DATA_WIDTH), .WINDOW_SIZE_BITS(WINDOW_SIZE_BITS), .MAX_TAU(MAX_TAU)) diff_tau (
            .clk(clk),
            .tau(6'b0),
            .reset(diff_reset[0]),
            .ready(diff_ready),
            .data_in(data),
            .accumulator(diff_results[0])
        );

genvar tau;
generate
    for (tau = 1; tau < MAX_TAU; tau = tau + 1) begin : diff_module
        wire ready_bit;
        diff_module #(.DATA_WIDTH(DATA_WIDTH), .WINDOW_SIZE_BITS(WINDOW_SIZE_BITS), .MAX_TAU(MAX_TAU)) diff_tau (
            .clk(clk),
            .tau(tau[5:0]),
            .reset(diff_reset[tau]),
            .ready(ready_bit),
            .data_in(data),
            .accumulator(diff_results[tau])
        );
    end
endgenerate

parameter DIV_SIZE_BITS = INTERMEDIATE_DATA_WIDTH;
// Modulo division
wire div_ready;
reg div_reset = 0;
reg new_div_reset = 0;
reg [DIV_SIZE_BITS-1:0] dividendo;
reg [DIV_SIZE_BITS-1:0] divisor;
wire [DIV_SIZE_BITS-1:0] div_result;
sar_divisor_module #(.BITS(DIV_SIZE_BITS)) sar_divisor_mod (
    .clk(clk),
    .ready(div_ready),
    .reset(div_reset),
    .dividendo(dividendo),
    .divisor(divisor),
    .result(div_result)   
);

// Registers
reg [WINDOW_SIZE_BITS-1:0]                          sum_index;
reg [WINDOW_SIZE_BITS-1:0]                          new_sum_index;
reg [INTERMEDIATE_DATA_WIDTH-1:0]                   accumulator;
reg [INTERMEDIATE_DATA_WIDTH-1:0]                   new_accumulator;
reg                                                 new_ready;

always @(posedge clk) begin
    if (reset) begin
        diff_reset = 0;
        diff_reset = ~diff_reset;
        sum_index <= 1;
        accumulator <= 0;
        ready <= 0;
        dividing <= 0;
        div_reset <= 0;
        total_sum <= 0;
        calculated_total_sum <= 0;
        calculated_average <= 0;
        average <= 0;
    end
    else begin
        diff_reset <= 0;
        sum_index <= new_sum_index;
        accumulator <= new_accumulator;
        ready <= new_ready;
        dividing <= new_dividing;
        div_reset <= new_div_reset;
        calculated_total_sum <= new_calculated_total_sum;
        calculated_average <= new_calculated_average;
        total_sum <= total_sum_comb;
        average <= new_average;
    end
end

reg dividing = 0;
reg new_dividing = 0;

reg [INTERMEDIATE_DATA_WIDTH-1:0] current = 0;
reg [INTERMEDIATE_DATA_WIDTH-1:0] current_result = 0;

reg calculated_total_sum;
reg new_calculated_total_sum;
reg calculated_average;
reg new_calculated_average;

reg [INTERMEDIATE_DATA_WIDTH-1:0] total_sum;
reg [INTERMEDIATE_DATA_WIDTH-1:0] total_sum_comb;

reg [INTERMEDIATE_DATA_WIDTH-1:0] new_average;

integer i;

always @(*) begin
    new_accumulator <= accumulator;
    new_sum_index <= sum_index;
    new_ready <= ready;
    new_dividing <= dividing;
    new_div_reset <= div_reset;
    new_calculated_total_sum <= calculated_total_sum;
    new_calculated_average <= calculated_average;
    new_average <= average;

    if (diff_ready & ~ready) begin
        // begin processing modified dtau
        current = diff_results[sum_index];
        if (!calculated_average) begin
            if (!calculated_total_sum) begin
                // Accumulation
                total_sum_comb = 'd0;
                for (i = 0; i < MAX_TAU; i = i + 1) begin
                    total_sum_comb = total_sum_comb + diff_results[i];
                end
                new_calculated_total_sum <= 1;
            end
            else begin
                // Average
                if (!dividing) begin
                    dividendo <= total_sum;
                    divisor <= MAX_TAU;
                    div_reset <= 1;
                    new_dividing <= 1;
                end
                else begin
                    if (div_reset) div_reset <= 0;
                    if (div_ready) begin
                        new_average <= div_result;
                        new_dividing <= 0;
                        results[0] <= div_result << 1;
                        new_calculated_average <= 1;
                    end
                end
            end
        end
        else if (!dividing & calculated_average) begin
            new_dividing <= 1;
            dividendo <= (current * average) * sum_index;
            divisor <= accumulator + current;
            new_accumulator <= accumulator + current;
            div_reset <= 1;
        end
        else begin
            if (div_reset) div_reset <= 0;
            if (div_ready) begin
                results[sum_index] <= div_result;
                current_result <= results[sum_index];
                new_dividing <= 0;
                new_sum_index <= sum_index + 1;
            end
        end
    end
    if (sum_index == MAX_TAU) begin
        new_ready <= 1;
    end
end

endmodule