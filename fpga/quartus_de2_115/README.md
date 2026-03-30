# Quartus DE2-115 / Cyclone IV E validation

This folder stores the Quartus-side CPU validation package separately from the mainline Basys 3 path.

## Why it is separate
The Quartus CPU version uses a different debug presentation: it exposes the full 32-bit debug register value directly across eight seven-segment displays. Because of that, the Quartus CPU top and some supporting RTL were kept together as their own validated package instead of being mixed into the mainline `rtl/` directory.

## Layout
- `cpu_validation/src/` : Quartus CPU RTL and FPGA top-level
- `cpu_validation/project/` : `.qpf` / `.qsf` project files
- `cpu_validation/waveforms/` : Quartus waveform files
- `constraints/` : original DE2-115 pin assignment reference file

## Device info from the Quartus project file
- Family: Cyclone IV E
- Top-level entity: `cpu_fpga_top`
