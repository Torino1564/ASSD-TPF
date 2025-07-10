module divisor_module #(
    parameter BITS = 16
) (
    input wire clk,
    input wire [BITS-1:0] dividendo,
    input wire [BITS-1:0] divisor,
    output reg [BITS-1:0] result,
    input wire reset,
    output reg ready
);
    // Usamos un divisor de busqueda lineal
    reg [BITS-1:0] new_result;
    reg [BITS-1:0] follower;
    reg [BITS-1:0] new_follower;
    reg new_ready = 0;

    always @(posedge clk ) begin
        if (reset) begin
            result <= 0;
            follower <= 0;
            ready <= 0;
        end
        else begin
            result <= new_result;
            ready <= new_ready;
            follower <= new_follower;
        end
    end

    always @(*) begin
        new_ready <= ready;
        new_follower <= follower;
        new_result <= result;

        if (!ready) begin
            if (follower < dividendo) begin
                new_result <= result + 1;
                new_follower <= follower + divisor;
            end
            else begin
                new_ready <= 1;
            end
        end
    end
endmodule