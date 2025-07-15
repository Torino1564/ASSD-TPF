`timescale 1ns/100ps

module top_tb;

reg clk = 1;
reg reset;
wire display_clk;
wire data_enable;
wire data_in;
wire serial_clock;
wire clear;
reg [7:0] audio;
reg eoc;

always
    #10 clk = ~clk;  

// dut
top top_dut(
    audio[0],
    audio[1],    
    audio[2],    
    audio[3],    
    audio[4],    
    audio[5],    
    audio[6],    
    audio[7],    
    eoc,

    display_clk,
    data_enable,
    data_in,
    serial_clock,
    clear,
    reset,
    clk
);
    
integer k;
initial begin
        // Dump de la simulación
        k = 0;
        reset = 1;
        audio = 127;
        $dumpfile("waveform.vcd");
        $dumpvars(0, top_tb);
        #200 reset = 0;
        #25600000 $finish;
    end

parameter FREQ = 800;
parameter FS = 20000;
parameter NUM_SAMPLES = $ceil(FS / FREQ);
reg [7:0] sin [NUM_SAMPLES];
integer i;
real value;
initial begin
        // Inicializo memoria con una onda seno escalada entre 0 y 255
        for (i = 0; i < NUM_SAMPLES; i = i + 1) begin
            // Valor en radianes (un ciclo completo cada BUFFER_SIZE muestras)
            value = $sin(2.0 * FREQ * 3.14159265 * i / FS);
            // Escalar a rango 0–255 para 8 bits sin signo
            sin[i] = $rtoi((value + 1.0) * 127.5);
        end
    end

always begin
        #25000 eoc = 1;
        k = k + 1;
        if (k >= NUM_SAMPLES) begin
            k = 0;
        end
        audio = sin[k];
        #25000 eoc = 0;
    end

endmodule