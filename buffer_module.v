module buffer_module
#(
    parameter DATA_WIDTH = 16,
    parameter DEPTH = 16,
    parameter ADDRESS_WIDTH = $clog2(DEPTH)
)
(
    input wire clk,
    input [ADDRESS_WIDTH-1:0] address,
    input [DATA_WIDTH-1:0] data_in,
    output [DATA_WIDTH-1:0] data_out,
    input wire write,
    input wire output_enable,
    input wire operational_clock
);

reg [DATA_WIDTH-1:0] buffer [DEPTH];
reg [DATA_WIDTH-1:0] temp_data;

always @(posedge clk) begin
    if (operational_clock & write) begin
        buffer[address] <= data_in;
    end
end

always @(posedge clk) begin
    if (operational_clock & !write) begin
        temp_data <= buffer[address];
    end
end

assign data_out = operational_clock & output_enable & !write ? temp_data : 'hz;
    
endmodule