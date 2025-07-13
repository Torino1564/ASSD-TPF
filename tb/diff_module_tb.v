`timescale 1ns/1ps

module diff_module_tb;

    parameter DATA_WIDTH_BITS = 8;
    parameter WINDOW_SIZE_BITS = 8; // 256 muestras (reducido para test rápido)
    parameter BUFFER_SIZE = 1 << (WINDOW_SIZE_BITS + 1);
    parameter FS = 2000;
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
    wire [((1<<WINDOW_SIZE_BITS)+MAX_TAU)*DATA_WIDTH_BITS-1:0] flat;
    genvar i;
    generate
        for (i = 0; i < (1<<WINDOW_SIZE_BITS)+MAX_TAU; i = i + 1) begin : flatten_loop
            assign flat[(i+1)*DATA_WIDTH_BITS-1 -: DATA_WIDTH_BITS] = memory[i];
        end
    endgenerate

    // Instancia del módulo
    diff_module #(
        .WINDOW_SIZE_BITS(WINDOW_SIZE_BITS),
        .DATA_WIDTH(DATA_WIDTH_BITS)
    ) dut (
        .clk(clk),
        .tau(tau),
        .reset(reset),
        .ready(ready),
        .data_in(flat),
        .accumulator(resultado_diferencias)
    );

initial begin
    // Inicializo memoria con una onda seno escalada entre 0 y 255
    integer i;
    real value;
    for (i = 0; i < 2*BUFFER_SIZE; i = i + 1) begin
        // Valor en radianes (un ciclo completo cada BUFFER_SIZE muestras)
        value = $sin(2.0 * 100 * 3.14159265 * i / FS);
        // Escalar a rango 0–255 para 8 bits sin signo
        memory[i] = $rtoi((value + 1.0) * 127.5);
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
        if (tau == 40) begin
            reset <= 1;
            total_ready <= 1;
        end
    end

    reg [7:0] mem_out = 0;
    initial begin
        integer j;
        for (j = 0; j < 2*BUFFER_SIZE; j = j + 1) begin
            #20 mem_out = memory[j];
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
