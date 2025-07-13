module sar_divisor_module #(
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
    reg [BITS-1:0] current_follower;
    reg [BITS-1:0] current_approximation;
    reg [BITS-1:0] new_current_follower;
    reg [BITS-1:0] new_current_approximation;
    reg [BITS-1:0] new_follower;
    reg new_ready = 0;
    reg under;
    reg new_under;

    always @(posedge clk ) begin
        if (reset) begin
            result <= 0;
            follower <= 0;
            ready <= 0;
            under <= 1;
            current_follower <= divisor;
            current_approximation <= 1;
        end
        else begin
            result <= new_result;
            ready <= new_ready;
            follower <= new_follower;
            under <= new_under;
            current_follower <= new_current_follower;
            current_approximation <= new_current_approximation;
        end
    end
    reg [BITS-1:0] comparator;
    reg [BITS-1:0] diff;

    always @(*) begin
        new_ready <= ready;
        new_follower <= follower;
        new_result <= result;
        new_under <= under;
        new_current_approximation <= current_approximation;
        new_current_follower <= current_follower;

        if (!ready) begin
            if (dividendo == 0 || divisor == 0) begin
                new_result <= 0;
                new_ready <= 1;
            end
            diff <= dividendo >= follower ? dividendo - follower : divisor + 1;
            if (diff < divisor) begin
                new_ready <= 1;
            end
            else if (under) begin
                comparator <= follower + current_follower;
                if (comparator < dividendo) begin
                    new_current_follower <= current_follower << 1;
                    new_current_approximation <= current_approximation << 1;
                end
                else begin
                    new_follower <= comparator;
                    new_result <= result + current_approximation;
                    new_under <= 0;
                    new_current_follower <= divisor;
                    new_current_approximation <= 1;
                end
            end
            else if (~under) begin
                comparator = follower - current_follower;
                if (comparator > dividendo) begin
                    new_current_follower <= current_follower << 1;
                    new_current_approximation <= current_approximation << 1;
                end
                else begin
                    new_follower <= comparator;
                    new_result <= result - current_approximation;
                    new_under <= 1;
                    new_current_follower <= divisor;
                    new_current_approximation <= 1;
                end
            end
        end
    end
endmodule