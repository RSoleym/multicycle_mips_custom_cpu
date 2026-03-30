module data_mem(
	input logic clk,
	input logic [12:0] addr,
	input logic [31:0] data_in,
	input logic wen,
	input logic en,
	output logic [31:0] data_out
);

	logic [31:0] mem_addr [2047:0];
	
	always_ff @(posedge clk) begin 
		if (en) begin
			if (!wen) data_out <= mem_addr[(addr>>2)];
			else mem_addr[(addr>>2)] <= data_in;
		end
	end

	
endmodule 