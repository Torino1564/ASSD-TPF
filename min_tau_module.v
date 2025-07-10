module min_tau_module #(
    parameter DATA_WIDTH = 8,
    parameter INTERMEDIATE_DATA_WIDTH = 64,
    parameter WINDOW_SIZE_BITS = 8,
    parameter MAX_TAU = 40,
    parameter THRESHOLD = 1
) (
    input wire clk,
    input wire reset,
    output reg ready,
    input wire [DATA_WIDTH*(2**WINDOW_SIZE_BITS + MAX_TAU)-1:0] data,
    output reg [7:0] min_tau
);
    wire [INTERMEDIATE_DATA_WIDTH-1:0] dt_prima [MAX_TAU];

    reg reset_modiff = 1;
    wire ready_modiff;
    wire [INTERMEDIATE_DATA_WIDTH-1:0] modiff_average;

    // Crear el modulo de dt':
    modiff_module #(
        .DATA_WIDTH(DATA_WIDTH),
        .INTERMEDIATE_DATA_WIDTH(INTERMEDIATE_DATA_WIDTH),
        .MAX_TAU(MAX_TAU),
        .WINDOW_SIZE_BITS(WINDOW_SIZE_BITS)    
    ) modiff_mod (
        .clk(clk),
        .data(data),
        .reset(reset_modiff),
        .ready(ready_modiff),
        .results(dt_prima),
        .average(modiff_average)
    );

    reg [INTERMEDIATE_DATA_WIDTH-1:0] divisor;
    reg [INTERMEDIATE_DATA_WIDTH-1:0] dividendo;
    reg [INTERMEDIATE_DATA_WIDTH-1:0] div_result;
    reg div_reset;
    wire div_ready;

    // Modulo de division
    sar_divisor_module #(.BITS(INTERMEDIATE_DATA_WIDTH)) divisor_mod (
        .clk(clk),
        .divisor(divisor),
        .dividendo(dividendo),
        .result(div_result),
        .ready(div_ready),
        .reset(div_reset)
    );

    // Registros
    reg new_ready = 0;
    reg [7:0] tau_index = 0;
    reg [7:0] new_tau_index = 0;

    reg [5:0] state;
    reg [5:0] new_state;
    localparam IDLE = 0;
    localparam FINDING_THRESHOLD = 1;
    localparam ITERATING = 2;
    localparam DONE = 3;
    localparam WAITING_THRESHOLD = 4;
    localparam SMALLEST_TAU = 5;

    reg [INTERMEDIATE_DATA_WIDTH-1:0] threshold;

    // Bloque syncronico
    always @(posedge clk ) begin
        if (~reset) begin
            ready <= new_ready;
            state <= new_state;
            tau_index <= new_tau_index;
            reset_modiff <= 0;
        end
        else begin
            state <= IDLE;
            ready <= 0;
            reset_modiff <= 1;
        end
    end

    // Bloque combinacional
    always @(*) begin
        new_state <= state;
        new_tau_index <= tau_index;

        case (state)
            IDLE: begin
                if (ready_modiff) begin
                    new_state <= FINDING_THRESHOLD;
                    new_tau_index <= 0;
                end
            end
            FINDING_THRESHOLD: begin
                dividendo <= modiff_average * THRESHOLD;
                divisor <= 100;
                div_reset <= 1;
                new_state <= WAITING_THRESHOLD;
            end
            WAITING_THRESHOLD: begin
                div_reset <= 0;
                if (div_ready) begin
                    threshold <= div_result;
                    new_state <= ITERATING;
                end
            end
            ITERATING: begin
                if (dt_prima[tau_index] < threshold) begin
                    min_tau <= tau_index;
                    new_state <= DONE;
                end
                new_tau_index <= tau_index + 1;
                if (tau_index == MAX_TAU - 1) begin
                    min_tau <= 0;
                    new_state <= DONE;
                end
            end
            DONE: begin
                new_ready <= 1;
            end
        endcase
    end
    
    
endmodule