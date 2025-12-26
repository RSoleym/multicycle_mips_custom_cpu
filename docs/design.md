Registers:
R0-R7
32-Bits

BRAM:
2kB for Instruction
4kB for Data

Instructions:
0000 -> LOAD: Loads a value from address into register
0001 -> STORE: Stores a register into an address
0010 -> ADD: Adds two registers
0011 -> SUB: Subtracts two registers
0100 -> AND: Returns one if the bit by bit values are one 
0101 -> BEQ: compares two registers if true then jumps to an address
0110 -> JMP: Jump to an address
0111 -> MOV: copies register to a register

Vivado stores the data in Instruction RAM, starting from address zero.
CPU Fetch, reads the Instructions using an increment from 0.

Instruction Fetch -> Instruction Decode -> Execute -> Memory Access -> Write Back

Instruction Fetch: 
- Increment Program Counter 
- Reads instruction set from the instruction address (Send Instruction Decode)

Instruction Decode: 
- Turn the instruction words into 4 Bit op-code
- ADD, SUB, AND, BEQ is for ALU
- JMP is for branch decision
- LOAD, STORE is for data handling
- MOV is for register handling 
 
Execute:
- ALU does the operations and sends the results to register handling, if BEQ is true sends the data to branch decision
- branch decision changes the Program counter to the designed instruction address 

Memory Access:
- data handling either loads or stores memory

Write Back:
- register handling updates the desired register


Source Modules:

cpu_fpga_top.sv
cpu_top.sv
if_stage.sv
id_stage.sv
alu.sv
ex_branch.sv 
mem_stage.sv
wb_stage.sv
pipeline_reg.sv
hazard_handle.sv
instr_mem.sv
data_mem.sv

Timeline:

Day 1 - Create Python Script, Assembly to Hex Values
Day 2 - Complete instr_mem.sv and Start if_stage.sv
Day 3 - Complete if_stage.sv and Start id_stage.sv
Day 4 - Work on id_stage.sv and Complete alu.sv
Day 5 - Complete id_stage.sv and Complete ex_branch.sv
Day 6 - Complete mem_stage.sv and Complete wb_stage.sv
Day 7 - Complete data_mem.sv and start pipeline_reg.sv
Day 8 - Complete pipeline_reg.sv and start hazard_handle.sv
Day 9 - Complete hazard_handle.sv
Day 10 - Complete cpu_top.sv and Start the UVM for cpu_tb.sv
Day 11 - Work on UVM
Day 12 - Work on UVM
Day 13 - Work on UVM
Day 14 - Complete UVM and run Simulation
Day 15 - Debug and fix errors
Day 16 - Complete cpu_fpga_top.sv and Debug on FPGA
Day 17 - Run on FPGA






