`timescale 1ns/1ps

module buffer_module_tb ();

reg clk = 1;
reg [3:0] address;
reg [15:0] data_in;
wire [15:0] data_out;
reg write = 1;
reg oe = 1;

buffer_module buffer_dut(
    .clk(clk),
    .address(address),
    .data_in(data_in),
    .data_out(data_out),
    .write(write),
    .output_enable(oe),
    .operational_clock(clk)
);

initial begin
    oe = 1;
    clk = 1'b0;
    forever begin
        #5 clk = ~clk;
    end
end

initial begin
    #1 write = 1;
    #1 data_in = 16'd123;
    #1 address = 0;
    #20 write = 0;

    #20 write = 1;
    #1 data_in = 16'd234;
    #1 address = 4'b1;
    #20 write = 0;

    #20 write = 1;
    #1 data_in = 16'd345;
    #1 address = 4'd2;
    #20 write = 0;

    #20 address = 0;
    #20 write = 0;
end

initial begin
    $dumpfile("waveform.vcd"); 
    $dumpvars(3);

    #200 $finish;
end

endmodule