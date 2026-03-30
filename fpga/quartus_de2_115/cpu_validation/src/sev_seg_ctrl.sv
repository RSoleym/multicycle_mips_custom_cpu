module sev_seg_ctrl(
	input logic clk,
	input logic rst_n,
	input logic [15:0] REG_dbg,
	output logic [6:0] HEX0,
	output logic [6:0] HEX1,
	output logic [6:0] HEX2,
	output logic [6:0] HEX3
);

	
	