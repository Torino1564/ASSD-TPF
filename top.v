
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

    wire diff_ready;
    wire [BUFFER_SIZE_BITS-1:0] diff_address;

    always @(posedge clk)
        address <= diff_address;

    diff_module #(
        .WINDOW_SIZE_BITS(WINDOW_SIZE_BITS),
        .DATA_WIDTH(DATA_WIDTH_BITS)
        )
        diff_mod (
            .clk(clk),
            .address(diff_address),
            .initial_address(0),
            .tau(0),
            .reset(0),
            .ready(diff_ready),
            .data_out(data_out)
        );



endmodule