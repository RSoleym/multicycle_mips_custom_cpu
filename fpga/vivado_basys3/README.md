# Basys 3 Vivado flow

This folder contains the FPGA top-level used for the Xilinx Basys 3 validation path.

## Contents
- `cpu_fpga_top.sv` : Basys 3 top-level with switch/button-driven debug display
- `Basys-3-Master.xdc` : board constraints

## Notes
This flow uses the mainline CPU RTL in the repository root. The Basys 3 path shows a 16-bit register window on the seven-segment display and uses a selector to toggle between lower and upper halves of the register value.
