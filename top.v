module top (
    // ports
    input wire [DATA_WIDTH_BITS-1:0] audio,
    input wire data_ready
);
    parameter BUFFER_SIZE_BITS = 11;
    parameter DATA_WIDTH_BITS = 16;

    parameter WINDOW_SIZE_BITS = 8; // W = 256 

    wire clk;

    SB_HFOSC HFOSC_mod(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk)); defparam HFOSC_mod.CLKHF_DIV = "0b00";

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




endmodule