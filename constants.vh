parameter DATA_WIDTH_BITS = 8;
parameter MAX_TAU = 40;
parameter THRESHOLD = 4;
parameter WINDOW_SIZE_BITS = 6; // W = 256 
parameter PASS_BUFFER_SIZE = 2 ** WINDOW_SIZE_BITS + MAX_TAU;
parameter BUFFER_SIZE = 2 * PASS_BUFFER_SIZE;