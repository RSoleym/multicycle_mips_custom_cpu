# multi_stage_mips_custom_cpu

This is a 32-bit MIPS-inspired multi-cycle CPU written in SystemVerilog. It supports 30+ instructions and includes separate instruction/data memory, a multi-cycle control FSM, and a simple debug setup to check PC/IR/ALUOut and register values during sim/FPGA testing.

## What’s included
- 32-bit datapath
- 16 general purpose registers (R0–R15)
  - R0 is always 0
  - R15 is used as the link register for JAL
- Multi-cycle control (fetch/decode/execute/mem/writeback sequencing)
- Separate instruction memory + data memory interfaces (Harvard Architecture)
- Loads/stores for word/byte/halfword
  - LW/SW
  - LB/LBU/SB
  - LH/LHU/SH
- Shifts (SLL/SRL/SRA)
- Multiply (MULLO/MULHI)
- Jumps/branches (JMP/JAL/JR/BEQ/BNE)
- Debug outputs: PC_dbg, IR_dbg, ALUOut_dbg, status_reg, and a register read port

## Supported instructions (30+)
Jumps/branches: JMP, JR, JAL, BEQ, BNE  
Memory: LW, SW, LB, LBU, SB, LH, LHU, SH  
Immediate: LUI, SLTI, ADDI, ANDI, ORI, XORI  
R-type: SLT, ADD, AND, OR, XOR, SUB, SLL, SRL, SRA, MULLO, MULHI  

(There’s also an ISA PDF in `docs/`.)

## Folder layout
- `rtl/` : all SystemVerilog RTL (datapath, controller, regfile, memories, ALU, multiplier, etc.)
- `tb/` : testbench
- `programs/` : assembly program + generated hex file
- `tools/` : python assembler (asm -> hex)
- `constraints/` : Basys 3 XDC and STA Test files
- `docs/` : ISA doc + screenshots (timing, test results, etc.)

## Top modules
- `rtl/cpu_top.sv` : connects IMEM + DMEM + datapath + control unit
- `rtl/datapath_multi.sv` : datapath with PC/IR/A/B/ALUOut/MDR latches
- `rtl/control_unit_multi.sv` : multi-cycle control FSM
- `rtl/cpu_fpga_top.sv` : Basys 3 wrapper + debug wiring

## How to run a program
The instruction memory loads from `programs/hex_instr.hex`. I write the program in:
- `programs/asm_instr.asm`

Then I generate the hex file using the python tool.

### Generate hex
From the project root:
```bash
python tools/asm_hex_conv.py
```

It will write/update:

programs/hex_instr.hex

## Simulation
Testbench: tb/cpu_tb.sv

The testbench runs the program until it detects the final “halt loop” (PC repeats), then prints the register values.

## FPGA (Basys 3)
Top: rtl/cpu_fpga_top.sv

Constraints: constraints/Basys-3-Master.xdc

After programming, the CPU ends in a self-jump so register values stay stable and can be checked using the debug register select.

## What Was Verified
Using a simple assembly smoke test program (programs/asm_instr.asm), I validated:

Static timing of the CPU for a 100 MHz System Clock

ALU ops + shifts + SLT/SLTI

MULLO/MULHI

SW then LW from the same address (store/load works)

SB with LB/LBU sign vs zero extension works

SH with LH/LHU sign vs zero extension works

JAL writes PC+4 into R15 and JR returns correctly

Program ends in a self-loop so the final register state is stable for debugging

## Notes
BEQ/BNE in this version jump using an absolute immediate target (datapath uses {imm16, 2'b00}).

SB/SH are handled using a read-modify-write sequence in the controller.