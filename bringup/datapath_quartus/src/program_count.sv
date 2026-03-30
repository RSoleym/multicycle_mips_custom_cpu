module program_count(
	input logic clk,
	input logic clr,
	input logic ld,
	input logic [31:0] d,
	output logic [31:0] q
);

	always_ff @ (posedge clk) begin
		if (clr) q <= 0;
		else if (ld) q <= d;
	end

endmodule
