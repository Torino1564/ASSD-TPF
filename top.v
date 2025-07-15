module top (
    // audio
    input wire gpio_11,     //  din_0
    input wire gpio_18,     //  din_1
    input wire gpio_19,     //  din_2
    input wire gpio_13,     //  din_3
    input wire gpio_21,     //  din_4
    input wire gpio_12,     //  din_5
    input wire gpio_10,     //  din_6
    input wire gpio_20,     //  din_7
    input wire gpio_6,      //  EOC

    // display
    output wire gpio_2,     //  display clock 
    output wire gpio_46,    //  data enable
    output wire gpio_47,    //  data in
    output wire gpio_45,    //  serial clock
    output wire gpio_48,     //  clear

    input wire gpio_9       // reset

    ,input wire clk
);
    `include "constants.vh" 
    //wire clk;

    // parameter DATA_WIDTH_BITS = 8;
    // parameter MAX_TAU = 40;
    // parameter THRESHOLD = 1;
    // parameter WINDOW_SIZE_BITS = 8; // W = 256 
    // parameter PASS_BUFFER_SIZE = 2 ** WINDOW_SIZE_BITS + MAX_TAU;
    // parameter BUFFER_SIZE = 2 * PASS_BUFFER_SIZE;

    wire eoc;
    wire reset;
    wire [DATA_WIDTH_BITS-1:0] audio;
    assign audio[0] = gpio_11;
    assign audio[1] = gpio_18;
    assign audio[2] = gpio_19;
    assign audio[3] = gpio_13;
    assign audio[4] = gpio_21;
    assign audio[5] = gpio_12;
    assign audio[6] = gpio_10;
    assign audio[7] = gpio_20;

    reg [DATA_WIDTH_BITS-1:0] current_audio;
    
    assign eoc = gpio_6;
    assign reset = gpio_9;

    localparam ADDRESS_WIDTH = $clog2(BUFFER_SIZE);

    //SB_HFOSC HFOSC_mod(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));
    //defparam HFOSC_mod.CLKHF_DIV = "0b00";

    reg [ADDRESS_WIDTH-1:0] address;
    reg [ADDRESS_WIDTH-1:0] new_address;
    reg [DATA_WIDTH_BITS-1:0] data_in;
    reg [DATA_WIDTH_BITS-1:0] new_data_in;
    wire [DATA_WIDTH_BITS-1:0] data_out;
    reg write = 1;
    reg new_write = 1;
    reg oe = 1;
    assign gpio_48 = 0;

    // ram module
    buffer_module #(.DEPTH(2*PASS_BUFFER_SIZE), .DATA_WIDTH(DATA_WIDTH_BITS)) buffer (
        .clk(clk),
        .address(address),
        .data_in(data_in),
        .data_out(data_out),
        .output_enable(oe),
        .operational_clock(1'b1),
        .write(write)
    );
    wire min_tau_ready;
    reg min_tau_reset;
    reg new_min_tau_reset;
    wire [7:0] min_tau_result;
    reg [7:0] tau;
    reg [7:0] new_tau;

    // display module
    display_module #(.WORDS(4)) display_mod (
        .VALUE_BCD({8'd0, tau}),
        .internal_clock(clk),
        .VALUE_SIGNAL(gpio_47),
        .ENABLE_SIGNAL(gpio_46),
        .BOARD_CLOCK_SIGNAL(gpio_2),
        .DATA_CLOCK_SIGNAL(gpio_45)
    );

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
            write <= new_write;
            data_in <= new_data_in;
            current_audio <= audio;
        end
        else begin
            memory_partition <= 0;
            state <= WAITING_DATA;
            address <= 0;
            first <= 0;
            fill_index <= 0;
            copy_index <= 0;
            current_buffer <= 1;
            tau <= 0;
            min_tau_reset <= 0;
            initial_address <= 0;
            dont_add_multiple_times <= 0;
            current_audio <= 0;
            data_in <= 0;
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
        new_address <= address;
        new_write <= write;
        new_data_in <= data_in;

        if (eoc == 1 & ~dont_add_multiple_times) begin
            new_dont_add_multiple_times <= 1;
            new_data_in <= current_audio;
            new_write <= 1;
            if (current_buffer == 1) begin
                new_address <= fill_index;
                new_fill_index <= fill_index + 1;
            end
            else begin
                new_address <= BUFFER_SIZE / 2 + fill_index;
                new_fill_index <= fill_index + 1;
            end
        end
        else begin
            new_write <= 0;
            if (eoc == 0)
                new_dont_add_multiple_times <= 0;
            case (state)
            SWITCH: begin
                // Set to process the new data
                if (current_buffer == 0) begin
                    new_current_buffer <= 1;
                    new_initial_address <= BUFFER_SIZE / 2 - 1;
                end
                else begin
                    new_current_buffer <= 0;
                    new_initial_address <= 0;
                end
                new_fill_index <= 0;
                new_copy_index <= 0;
                new_state <= COPYING_DATA;
                new_first <= 1;
            end
            COPYING_DATA: begin
                if (first) begin
                    new_first <= 0;
                    new_address <= initial_address + copy_index;
                    new_copy_index <= copy_index + 1;
                end
                else begin
                    new_address <= initial_address + copy_index;
                    if (copy_index == PASS_BUFFER_SIZE + 2) begin
                        new_min_tau_reset <= 1;
                        new_state <= WAITING_PROCESSING;
                        new_copy_index <= 0;
                    end
                    else begin
                        new_memory_partition[(copy_index-2)*DATA_WIDTH_BITS+:DATA_WIDTH_BITS] <= data_out;
                        new_copy_index <= copy_index + 1;
                    end
                end
            end
            WAITING_PROCESSING: begin
                if (min_tau_reset == 1)
                    new_min_tau_reset <= 0;
                else if (min_tau_ready) begin
                    //if (min_tau_result != 0) begin
                        new_tau <= min_tau_result;
                    //end
                    new_state <= WAITING_DATA;
                end
            end
            WAITING_DATA: begin
                if (fill_index == PASS_BUFFER_SIZE) begin
                    new_state <= SWITCH; 
                end
            end
            endcase
        end
    end
endmodule