`timescale 1ns/100ps

module top_tb;
    // audio

    parameter DATA_WIDTH_BITS = 8;
    parameter MAX_TAU = 40;
    parameter THRESHOLD = 1;
    parameter WINDOW_SIZE_BITS = 6; // W = 256 
    parameter PASS_BUFFER_SIZE = 2 ** WINDOW_SIZE_BITS + MAX_TAU;
    parameter BUFFER_SIZE = 2 * PASS_BUFFER_SIZE;

    reg clk = 1;
    reg eoc;
    reg [DATA_WIDTH_BITS-1:0] audio;
    

    localparam ADDRESS_WIDTH = $clog2(BUFFER_SIZE);

    always
        #10 clk = ~clk;

    reg [ADDRESS_WIDTH-1:0] address;
    reg [ADDRESS_WIDTH-1:0] new_address;
    reg [DATA_WIDTH_BITS-1:0] data_in;
    wire [DATA_WIDTH_BITS-1:0] data_out;
    reg write = 1;
    reg oe = 1;
    assign gpio_48 = 0;

    // ram module
    buffer_module #(.DEPTH(2*PASS_BUFFER_SIZE), .DATA_WIDTH(DATA_WIDTH_BITS)) buffer_dut (
        .clk(clk),
        .address(address),
        .data_in(data_in),
        .data_out(data_out),
        .output_enable(oe),
        .operational_clock(1'b1),
        .write(write)
    );
    reg reset;
    wire min_tau_ready;
    reg min_tau_reset;
    reg new_min_tau_reset;
    wire [7:0] min_tau_result;
    reg [7:0] tau;
    reg [7:0] new_tau;

    // double buffering
    reg [PASS_BUFFER_SIZE*DATA_WIDTH_BITS-1:0] memory_partition;
    reg [PASS_BUFFER_SIZE*DATA_WIDTH_BITS-1:0] new_memory_partition;

    min_tau_module #(
        .DATA_WIDTH(DATA_WIDTH_BITS),
        .INTERMEDIATE_DATA_WIDTH(64),
        .WINDOW_SIZE_BITS(WINDOW_SIZE_BITS),
        .MAX_TAU(MAX_TAU),
        .THRESHOLD(THRESHOLD)
    ) min_tau_mod (
        .clk(clk),
        .reset(min_tau_reset),
        .ready(min_tau_ready),
        .min_tau(min_tau_result),
        .data(memory_partition)
    );

    reg [7:0] state;
    reg [7:0] new_state;

    reg current_buffer;
    reg new_current_buffer;

    reg [ADDRESS_WIDTH-1:0] fill_index;
    reg [ADDRESS_WIDTH-1:0] new_fill_index;

    localparam SWITCH = 1;
    localparam COPYING_DATA = 2;
    localparam WAITING_PROCESSING = 3;
    localparam WAITING_DATA = 4;

    always @(posedge clk) begin
        if (reset == 0) begin
            state <= new_state;
            address <= new_address;
            first <= new_first;
            fill_index <= new_fill_index;
            copy_index <= new_copy_index;
            current_buffer <= new_current_buffer;
            tau <= new_tau;
            min_tau_reset <= new_min_tau_reset;
            initial_address <= new_initial_address;
            memory_partition <= new_memory_partition;
            dont_add_multiple_times <= new_dont_add_multiple_times;
        end
        else begin
            memory_partition <= 0;
            state <= WAITING_DATA;
            address <= 0;
            first <= 0;
            fill_index <= 0;
            copy_index <= 0;
            current_buffer <= 0;
            tau <= 0;
            min_tau_reset <= 0;
            initial_address <= 0;
            dont_add_multiple_times <= 0;
        end
    end

    reg set_address;
    reg new_set_address;

    reg [ADDRESS_WIDTH-1:0] initial_address;
    reg [ADDRESS_WIDTH-1:0] new_initial_address;
    reg [ADDRESS_WIDTH-1:0] copy_index;
    reg [ADDRESS_WIDTH-1:0] new_copy_index;
    reg new_first;
    reg first;

    reg dont_add_multiple_times;
    reg new_dont_add_multiple_times;

    always @(*) begin
        new_state <= state;
        new_set_address <= set_address;
        new_first <= first;
        new_fill_index <= fill_index;
        new_copy_index <= copy_index;
        new_current_buffer <= current_buffer;
        new_tau <= tau;
        new_min_tau_reset <= min_tau_reset;
        new_initial_address <= initial_address;
        new_memory_partition <= memory_partition;
        new_dont_add_multiple_times <= dont_add_multiple_times;

        if (eoc == 1 & ~dont_add_multiple_times) begin
            new_dont_add_multiple_times <= 1;
            if (current_buffer == 1) begin
                new_address <= fill_index;
                new_fill_index <= fill_index + 1;
            end
            else begin
                new_address <= BUFFER_SIZE / 2 + fill_index;
                new_fill_index <= fill_index + 1;
            end
            data_in <= audio;
        end
        else begin
            if (eoc == 0)
                new_dont_add_multiple_times <= 0;
            case (state)
            SWITCH: begin
                // Set to process the new data
                if (current_buffer == 0) begin
                    new_current_buffer <= 1;
                    new_initial_address <= BUFFER_SIZE / 2;
                    new_fill_index <= 0;
                end
                else begin
                    new_current_buffer <= 0;
                    new_initial_address <= 0;
                    new_fill_index <= BUFFER_SIZE / 2;
                end
                new_copy_index <= 0;
                new_state <= COPYING_DATA;
                new_first <= 1;
            end
            COPYING_DATA: begin
                if (first) begin
                    new_first <= 0;
                    new_address <= initial_address + copy_index;
                end
                else begin
                    new_address <= initial_address + copy_index;
                    if (copy_index == BUFFER_SIZE) begin
                        new_min_tau_reset <= 1;
                        new_state <= WAITING_PROCESSING;
                        new_copy_index <= 0;
                    end
                    else begin
                        new_memory_partition[copy_index*DATA_WIDTH_BITS+:DATA_WIDTH_BITS] <= data_out;
                        new_copy_index <= copy_index + 1;
                    end
                end
            end
            WAITING_PROCESSING: begin
                new_min_tau_reset <= 0;
                if (min_tau_ready) begin
                    //if (min_tau_result != 0) begin
                        new_tau <= min_tau_result;
                    //end
                    new_state <= WAITING_DATA;
                end
            end
            WAITING_DATA: begin
                if (current_buffer == 0) begin
                    if (fill_index == BUFFER_SIZE - 1) begin
                       new_state <= SWITCH; 
                    end
                end
                else begin
                    if (fill_index == BUFFER_SIZE/2 - 1) begin
                        new_state <= SWITCH;
                    end
                end
            end
            endcase
        end
    end
integer k;
initial begin
        // Dump de la simulación
        k = 0;
        reset = 1;
        $dumpfile("waveform.vcd");
        $dumpvars(0, top_tb);
        #100 reset = 0;
        
        #256000000 $finish;
    end

parameter FREQ = 100;
reg [DATA_WIDTH_BITS-1:0] sin [200];
integer i;
real value;
initial begin
        // Inicializo memoria con una onda seno escalada entre 0 y 255
        for (i = 0; i < 200; i = i + 1) begin
            // Valor en radianes (un ciclo completo cada BUFFER_SIZE muestras)
            value = $sin(2.0 * FREQ * 3.14159265 * i / 2000);
            // Escalar a rango 0–255 para 8 bits sin signo
            sin[i] = $rtoi((value + 1.0) * 127.5);
        end
    end

always begin
        #250000 eoc = 1;
        k = k + 1;
        if (k >= 200) begin
            k = 0;
        end
        #1 audio = sin[k];
        #250000 eoc = 0;
    end

endmodule