#!/bin/bash

# Compile the source files and testbench using iverilog
# -o tb_fifo : Specifies the name of the output compiled executable
iverilog -o tb_async_fifo.vvp ../src/async_fifo.v tb_async_fifo.v

# Execute the compiled simulation file using vvp
vvp tb_async_fifo.vvp

# View the waveform using GTKWave
gtkwave tb_async_fifo.vcd