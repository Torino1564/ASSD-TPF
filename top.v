
module top (
    // ports
    // input wire [DATA_WIDTH_BITS-1:0] audio,
    // input wire data_ready
);
    `include "constants.vh" 
    wire clk;

    SB_HFOSC HFOSC_mod(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));
    //defparam HFOSC_mod.CLKHF_DIV = "0b00";

    reg [BUFFER_SIZE_BITS-1:0] address;
    reg [DATA_WIDTH_BITS-1:0] data_in;
    wire [DATA_WIDTH_BITS-1:0] data_out;
    reg write = 1;
    reg oe = 1;

    // ram module
    buffer_module #(.DEPTH(2 ** BUFFER_SIZE_BITS), .ADDRESS_WIDTH(BUFFER_SIZE_BITS), .DATA_WIDTH(DATA_WIDTH_BITS)) buffer_dut(
        .clk(clk),
        .address(address),
        .data_in(data_in),
        .data_out(data_out),
        .output_enable(oe),
        .operational_clock(1'b1),
        .write(write)
    );

    wire ready;
    reg reset;
    wire [BUFFER_SIZE_BITS-1:0] diff_address;
    wire [7:0] result;

    always @(posedge clk)
        address <= diff_address;

    // Flatten address
    wire [((1<<WINDOW_SIZE_BITS)+MAX_TAU)*DATA_WIDTH_BITS-1:0] flat;
    genvar i;
    generate
        for (i = 0; i < (1<<WINDOW_SIZE_BITS)+MAX_TAU; i = i + 1) begin : flatten_loop
            assign flat[(i+1)*DATA_WIDTH_BITS-1 -: DATA_WIDTH_BITS] = memory[i + buffer_offset];
        end
    endgenerate

    min_tau_module #(
        .DATA_WIDTH(DATA_WIDTH_BITS),
        .INTERMEDIATE_DATA_WIDTH(64),
        .WINDOW_SIZE_BITS(WINDOW_SIZE_BITS),
        .MAX_TAU(MAX_TAU),
        .THRESHOLD(THRESHOLD),
    ) min_tau_mod (
        .clk(clk),
        .reset(reset),
        .ready(ready),
        .min_tau(result),
        .data()
    );



endmodule