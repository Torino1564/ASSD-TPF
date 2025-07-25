`timescale 1ns/1ps

module modiff_module_tb;

    parameter DATA_WIDTH_BITS = 8;
    parameter WINDOW_SIZE_BITS = 8; // 256 muestras (reducido para test rápido)
    parameter BUFFER_SIZE = 1 << (WINDOW_SIZE_BITS + 1);
    parameter FS = 2000;
    parameter MAX_TAU = 40; // representa 20ms
    parameter INTERMEDIATE_DATA_WIDTH = 64;

    reg clk = 1;
    always #5 clk = ~clk;  // Clock de 100MHz

    reg reset = 1;
    reg [5:0] tau = 0;
    wire ready;

    // Memoria simulada con BUFFER_SIZE entradas
    reg [DATA_WIDTH_BITS-1:0] memory [0:2*BUFFER_SIZE-1];

    wire [((1<<WINDOW_SIZE_BITS)+MAX_TAU)*DATA_WIDTH_BITS-1:0] flat;
    genvar i;
    generate
        for (i = 0; i < (1<<WINDOW_SIZE_BITS)+MAX_TAU; i = i + 1) begin : flatten_loop
            assign flat[(i+1)*DATA_WIDTH_BITS-1 -: DATA_WIDTH_BITS] = memory[i];
        end
    endgenerate

    wire [INTERMEDIATE_DATA_WIDTH-1:0] dt_prima [MAX_TAU];


    // Instancia del módulo
    modiff_module #(
        .WINDOW_SIZE_BITS(WINDOW_SIZE_BITS),
        .DATA_WIDTH(DATA_WIDTH_BITS),
        .MAX_TAU(MAX_TAU),
        .INTERMEDIATE_DATA_WIDTH(INTERMEDIATE_DATA_WIDTH)
    ) modiff_dut (
        .clk(clk),
        .reset(reset),
        .ready(ready),
        .data(flat),
        .results(dt_prima)
    );

    initial begin
        // Inicializo memoria con una onda seno escalada entre 0 y 255
        integer i;
        real value;
        for (i = 0; i < 2*BUFFER_SIZE; i = i + 1) begin
            // Valor en radianes (un ciclo completo cada BUFFER_SIZE muestras)
            value = $sin(2.0 * 105.26 * 3.14159265 * i / FS);
            // Escalar a rango 0–255 para 8 bits sin signo
            memory[i] = $rtoi((value + 1.0) * 127.5);
        end
    end
    

    reg [DATA_WIDTH_BITS-1:0] mem_out = 0;
    initial begin
        integer j;
        for (j = 0; j < 2*BUFFER_SIZE; j = j + 1) begin
            #20 mem_out = memory[j];
        end
    end

    reg [INTERMEDIATE_DATA_WIDTH-1:0] dt_prima_out = 0;
    reg done_displaying = 0;
    integer k;
    initial begin
        #10 wait (ready == 1);
        for (k = 0; k < MAX_TAU; k = k + 1) begin
            #20 dt_prima_out = dt_prima[k];
        end
        done_displaying = 1;
    end

    initial begin
        // Dump de la simulación
        $dumpfile("waveform.vcd");
        $dumpvars(0, modiff_module_tb);
        #20 reset = 0;
        wait (done_displaying == 1);
        #20 $finish;
    end
endmodule