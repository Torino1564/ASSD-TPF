module modiff_module
#(
    parameter DATA_WIDTH = 8,
    parameter INTERMEDIATE_DATA_WIDTH = 64,
    parameter WINDOW_SIZE_BITS = 8,
    parameter MAX_TAU = 40
) (
    input wire clk,
    input wire reset,
    input wire [(2**WINDOW_SIZE_BITS + MAX_TAU)
                *DATA_WIDTH-1:0] data,
    output reg ready,
    output reg [MAX_TAU*INTERMEDIATE_DATA_WIDTH-1:0] results,
    output reg [INTERMEDIATE_DATA_WIDTH-5:0] average
);

wire [INTERMEDIATE_DATA_WIDTH-1:0] diff_result;
reg [INTERMEDIATE_DATA_WIDTH-1:0] curr;
reg [MAX_TAU*INTERMEDIATE_DATA_WIDTH-1:0] diff_results;
reg [MAX_TAU*INTERMEDIATE_DATA_WIDTH-1:0] new_diff_results;
wire diff_ready;
reg diff_reset = 0;
reg new_diff_reset = 0;

reg [MAX_TAU*INTERMEDIATE_DATA_WIDTH-1:0] new_results;
reg [$clog2(MAX_TAU)-1:0] tau;
reg [$clog2(MAX_TAU)-1:0] new_tau;

diff_module #(.DATA_WIDTH(DATA_WIDTH), .WINDOW_SIZE_BITS(WINDOW_SIZE_BITS), .MAX_TAU(MAX_TAU), .INTERMEDIATE_DATA_WIDTH(INTERMEDIATE_DATA_WIDTH)) diff_tau (
            .clk(clk),
            .tau(tau),
            .reset(diff_reset),
            .ready(diff_ready),
            .data_in(data),
            .accumulator(diff_result)
        );

parameter DIV_SIZE_BITS = INTERMEDIATE_DATA_WIDTH + 10;
// Modulo division
wire div_ready;
reg div_reset = 0;
reg new_div_reset = 0;
reg [DIV_SIZE_BITS-1:0] dividendo;
reg [DIV_SIZE_BITS-1:0] new_dividendo;
reg [DIV_SIZE_BITS-1:0] divisor;
reg [DIV_SIZE_BITS-1:0] new_divisor;
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
reg [INTERMEDIATE_DATA_WIDTH+4:0]                   accumulator;
reg [INTERMEDIATE_DATA_WIDTH+4:0]                   new_accumulator;
reg                                                 new_ready;
reg calculated_diff;
reg new_calculated_diff;
always @(posedge clk) begin
    if (reset) begin
        diff_reset <= 1;
        sum_index <= 0;
        accumulator <= 0;
        ready <= 0;
        dividing <= 0;
        div_reset <= 0;
        total_sum <= 0;
        calculated_total_sum <= 0;
        calculated_average <= 0;
        average <= 0;
        first <= 1;
        total_sum_index <= 0;
        divisor <= 0;
        dividendo <= 0;
        results <= 0;
        calculated_diff <= 0;
        tau <= 0;
        diff_results <= 0;
    end
    else begin
        first <= new_first;
        diff_reset <= new_diff_reset;
        sum_index <= new_sum_index;
        accumulator <= new_accumulator;
        ready <= new_ready;
        dividing <= new_dividing;
        div_reset <= new_div_reset;
        calculated_total_sum <= new_calculated_total_sum;
        calculated_average <= new_calculated_average;
        total_sum <= new_total_sum;
        total_sum_index <= new_total_sum_index;
        average <= new_average;
        divisor <= new_divisor;
        dividendo <= new_dividendo;
        results <= new_results;
        calculated_diff <= new_calculated_diff;
        tau <= new_tau;
        diff_results <= new_diff_results;
    end
end

reg dividing = 0;
reg new_dividing = 0;
reg first;
reg new_first;

reg [INTERMEDIATE_DATA_WIDTH-1:0] current = 0;
reg [INTERMEDIATE_DATA_WIDTH-1:0] current_result = 0;

reg calculated_total_sum;
reg new_calculated_total_sum;
reg calculated_average;
reg new_calculated_average;

localparam UP_TO_MAX_TAU = $clog2(MAX_TAU);

reg [INTERMEDIATE_DATA_WIDTH+2:0] total_sum;
reg [INTERMEDIATE_DATA_WIDTH+2:0] new_total_sum;
reg [UP_TO_MAX_TAU-1:0] total_sum_index;
reg [UP_TO_MAX_TAU-1:0] new_total_sum_index;

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
    new_total_sum <= total_sum;
    new_total_sum_index <= total_sum_index;
    new_divisor <= divisor;
    new_dividendo <= dividendo;
    new_results <= results;
    new_calculated_diff <= calculated_diff;
    new_tau <= tau;
    new_diff_results <= diff_results;
    new_diff_reset <= diff_reset;
    new_first <= first;
    
    if (calculated_diff & sum_index == MAX_TAU) begin
        new_ready <= 1;
    end
    else if (!calculated_diff & tau == MAX_TAU) begin
        new_calculated_diff <= 1;
        new_sum_index <= 1;
        new_first <= 1;
    end
    else if (!calculated_diff) begin
        new_diff_reset <= 0;
        new_tau <= tau;
        if (first)
            new_first <= 0;
        else if (diff_ready) begin
            new_diff_results[tau*INTERMEDIATE_DATA_WIDTH+:INTERMEDIATE_DATA_WIDTH] <= diff_result;
            new_tau <= tau + 1;
            new_diff_reset <= 1;
            new_total_sum <= total_sum + diff_result;
            new_first <= 1;
        end
    end
    else if (first)
        new_first <= 0;
    else if (calculated_diff & ~reset & ~ready & ~first) begin
        // begin processing modified dtau
        if (!calculated_average) begin
            // Average
            if (!dividing) begin
                new_dividendo <= total_sum;
                new_divisor <= MAX_TAU;
                new_div_reset <= 1;
                new_dividing <= 1;
            end
            else begin
                if (div_reset) new_div_reset <= 0;
                else if (div_ready) begin
                    new_average <= div_result >> 4;
                    new_dividing <= 0;
                    new_results[0+:INTERMEDIATE_DATA_WIDTH] <= div_result;
                    new_calculated_average <= 1;
                end
            end
            
        end
        else if (!dividing & calculated_average) begin
            new_dividing <= 1;
            curr = diff_results[sum_index*INTERMEDIATE_DATA_WIDTH+:INTERMEDIATE_DATA_WIDTH];
            new_dividendo <= (((curr >> 7) * average) * sum_index);
            new_divisor <= (accumulator + curr ) >> 7;
            new_accumulator <= (accumulator + curr) >> 7;
            new_div_reset <= 1;
        end
        else begin
            if (div_reset) new_div_reset <= 0;
            else if (div_ready) begin
                new_results[sum_index*INTERMEDIATE_DATA_WIDTH+:INTERMEDIATE_DATA_WIDTH] <= div_result;
                new_dividing <= 0;
                new_sum_index <= sum_index + 1;
            end
        end
    end
end

endmodule