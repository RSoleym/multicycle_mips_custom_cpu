# Custom 32-bit Mips Style Multi-Cycle CPU

A 32-bit MIPS-inspired multi-cycle CPU written in SystemVerilog, with simulation support, Basys 3 FPGA validation in Vivado, and a separate Quartus bring-up for Intel/Altera hardware.

## Highlights
- 32-bit multi-cycle CPU
- 16 general-purpose registers (R0-R15)
  - R0 is hard-wired to zero
  - R15 is used as the link register for `JAL`
- Separate instruction and data memories (Harvard-style organization)
- Load/store support for word, halfword, and byte accesses
- Arithmetic, logic, shifts, branches, jumps, and multiply
- Debug visibility for `PC`, `IR`, `ALUOut`, status flags, and register contents
- Simulation testbench plus simple SVA checks
- FPGA-oriented debug paths for both Xilinx and Intel/Altera flows

## Supported instruction groups
- **Branches / jumps:** `JMP`, `JR`, `JAL`, `BEQ`, `BNE`
- **Memory:** `LW`, `SW`, `LB`, `LBU`, `SB`, `LH`, `LHU`, `SH`
- **Immediate:** `LUI`, `SLTI`, `ADDI`, `ANDI`, `ORI`, `XORI`
- **R-type:** `SLT`, `ADD`, `AND`, `OR`, `XOR`, `SUB`, `SLL`, `SRL`, `SRA`, `MULLO`, `MULHI`

## Repository layout
```text
configurable_32bit_cpu/
├─ rtl/
├─ tb/
├─ programs/
├─ tools/
├─ sta/
├─ docs/
├─ fpga/
│  ├─ vivado_basys3/
│  └─ quartus_de2_115/
└─ bringup/
   └─ datapath_quartus/
```

## Main source folders
### `rtl/`
Mainline CPU RTL used by the current simulation flow and the Xilinx/Basys 3 side of the project. This includes the full CPU integration top (`cpu_top.sv`), datapath, controller, ALU, memories, register file, and support modules.

### `tb/`
Simulation testbench and SVA checker. The current testbench targets the mainline `rtl/cpu_top.sv` flow.

### `programs/`
Assembly input plus generated instruction-memory hex files.
- `asm_instr.asm` = program source
- `hex_instr.hex` = generated program image
- `instr.hex` = compatibility copy for flows that expect that filename

### `tools/`
Utility scripts, including the Python assembler that converts the custom assembly program into a hex file for instruction memory.

### `fpga/vivado_basys3/`
Basys 3 FPGA top-level and constraints for the Xilinx flow.

### `fpga/quartus_de2_115/cpu_validation/`
Quartus CPU validation package targeting a Cyclone IV E device. This folder is kept as a separate validated flow because its debug presentation differs from the mainline Basys 3 setup. In particular, the Quartus CPU version exposes the full 32-bit debug register value directly across eight seven-segment displays, while the Basys 3 path uses a 16-bit window with a selector.

### `bringup/datapath_quartus/`
Earlier datapath-only Quartus bring-up package kept separately from the full CPU project. This is useful to show the design progression from subsystem verification to full CPU integration.

## Top modules
### Mainline CPU
- `rtl/cpu_top.sv`
- `rtl/datapath_multi.sv`
- `rtl/ctrl_unit.sv` (module name: `control_unit_multi`)

### Basys 3 FPGA
- `fpga/vivado_basys3/cpu_fpga_top.sv`

### Quartus CPU validation
- `fpga/quartus_de2_115/cpu_validation/src/cpu_fpga_top.sv`
- `fpga/quartus_de2_115/cpu_validation/src/cpu_top.sv`

### Datapath bring-up
- `bringup/datapath_quartus/src/datapath_top.sv`

## Simulation
Current simulation assets are under `tb/`. The instruction memory now loads from `programs/hex_instr.hex`, which matches the assembler output in `tools/asm_hex_conv.py`.

### Generate instruction memory hex
From the repository root:
```bash
python tools/asm_hex_conv.py
```

## Assertion-based verification
`tb/cpu_sva.sv` contains simple checks used during simulation, including:
- PC alignment
- authorized PC / IR updates
- memory write-enable sanity
- R0 immutability

## FPGA notes
- The **Basys 3** flow is the cleaner mainline GitHub path.
- The **Quartus CPU** flow is included as a separate validated hardware path for Cyclone IV E / DE2-115-style hardware.
- The **datapath Quartus** folder is kept as a staged bring-up artifact rather than merged into the full CPU tree.

## Design note
This repository intentionally keeps the Quartus CPU validation files and the datapath-only Quartus bring-up in separate folders instead of force-merging them into the mainline `rtl/` tree. That avoids mixing two different debug presentations into one top-level file and keeps each validated hardware flow readable.
