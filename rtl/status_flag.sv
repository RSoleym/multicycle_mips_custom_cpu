module status_flag(
	input logic clk,
	input logic rst_n,
	input logic [3:0] clr_flag,
	input logic flag_en,
	input logic [3:0] flag_val,
	input logic mode,
	output logic [31:0] status_reg
);
	
	int i;
	logic [3:0] flag_stats;
	
	assign status_reg = {flag_stats, 27'b0, mode};
	
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			flag_stats <= 0;
		else begin
			for (i = 0; i < 4; i = i + 1) begin
				if (clr_flag[i])
					flag_stats[i] <= 0;
				else if (flag_en) 
					flag_stats[i] <= flag_val[i];
			end
		end
	end
	
endmodule 