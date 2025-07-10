`timescale 1ns/1ps

module sar_divisor_module_tb;
    parameter BITS = 40;
    reg clk = 1;
    always #5 clk = ~clk;

    reg [39:0] dividendo;
    reg [39:0] divisor;
    reg [39:0] result;
    reg reset;
    wire ready;

    sar_divisor_module #(.BITS(BITS)) dut (
        .clk(clk),
        .dividendo(dividendo),
        .divisor(divisor),
        .result(result),
        .reset(reset),
        .ready(ready)
    );

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, sar_divisor_module_tb);
        #0 reset = 1;
        dividendo = 40'd425_332_234;
        divisor = 40'd62_254;

        #20 reset = 0;
        wait (ready == 1);
        #20 $finish;
    end

endmodule