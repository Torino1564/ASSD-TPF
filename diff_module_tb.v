`timescale 1ns/1ps

module diff_module_tb;

    parameter DATA_WIDTH_BITS = 16;
    parameter WINDOW_SIZE_BITS = 4; // 16 muestras (reducido para test rápido)
    parameter BUFFER_SIZE = 1 << WINDOW_SIZE_BITS;
    parameter MAX_TAU = 40; // representa 20ms

    reg clk = 1;
    always #5 clk = ~clk;  // Clock de 100MHz

    reg reset = 1;
    reg [15:0] initial_address = 0;
    reg [5:0] tau = 0;
    wire [15:0] address;
    wire ready;

    // Memoria simulada con BUFFER_SIZE entradas
    reg [DATA_WIDTH_BITS-1:0] memory [0:2*BUFFER_SIZE-1];

    // Salida actual del dato leído
    reg [DATA_WIDTH_BITS-1:0] data_out = 0;

    // Resultado de la funcion de diferencias
    reg [38:0] resultados [MAX_TAU];
    wire [38:0] resultado_diferencias;

    // Instancia del módulo
    diff_module #(
        .WINDOW_SIZE_BITS(WINDOW_SIZE_BITS),
        .DATA_WIDTH(DATA_WIDTH_BITS)
    ) dut (
        .clk(clk),
        .address(address),
        .initial_address(initial_address),
        .tau(tau),
        .reset(reset),
        .ready(ready),
        .data_out(data_out),
        .accumulator(resultado_diferencias)
    );

    initial begin
        // Inicializo memoria con algunos datos de prueba
        integer i;
        for (i = 1; i < 2*BUFFER_SIZE + 1; i = i + 1) begin
            memory[i-1] = i;  // Datos lineales: 0, 1, 2, ..., 31
        end
    end

    // Simula lectura de memoria
    always @(posedge clk) begin
        data_out <= memory[address];
    end
    
    reg total_ready = 0;
    reg detected = 0;
    reg delay = 0;
    always @(posedge clk) begin
        if (ready == 1 & ~detected) begin
            detected <= 1;
        end
        else if (ready == 1 & detected & ~delay) begin
            delay <= 1;
            tau <= tau + 1;
            reset <= 1;
        end
        else if (ready == 0) begin
            delay <= 0;
            reset <= 0;
        end
        if (tau > 3) begin
            reset <= 1;
            total_ready <= 1;
        end
    end

    initial begin
        // Dump de la simulación
        $dumpfile("waveform.vcd");
        $dumpvars(0, diff_module_tb);

        wait (total_ready == 1);
        #20 $finish;
    end

endmodule
