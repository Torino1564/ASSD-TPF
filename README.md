Para simular el programa. Revisar que el wire clk del top esté comentado y descomentar el input wire clk. Comentar tambien el modulo HFOSC.
Para setear el período de la señal cambiar en top_tb.v el valor de FREQ y FS. Comando iverilog:
iverilog top_tb.v top.v display_module.v buffer_module.v sar_divisor_module.v min_tau_module.v modiff_module.v diff_module.v
vvp a.out
Para buildear en fpga comentar el input wire clk del top y descomentar el oscilador y el wire clk. Los parametros estan en constants.vh
apio build -v
