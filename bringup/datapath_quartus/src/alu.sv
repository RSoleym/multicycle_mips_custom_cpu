module alu (
	input logic signed [31:0] a,
	input logic signed [31:0] b,
	input logic [4:0] shamt,
	input logic [3:0] op,
	output logic signed [31:0] result,
	output logic cout,
	output logic zero,
	output logic over,
	output logic neg
);
	
	assign zero = (result == 32'b0);
	assign neg = result[31];
	
	
	always_comb begin	
		result = 0;
		cout = 0;
		over = 0;
		case (op)
			4'b0000 ://ADD
			begin
				{cout, result} = {1'b0, a} + {1'b0, b}; 				
				over = (~(a[31] ^ b[31])) & (a[31] ^ result[31]);
			end 
			4'b0001 ://SUB
			begin 
				{cout, result} = {1'b0, a} - {1'b0, b}; 				
				over = (a[31] ^ b[31]) & (a[31] ^ result[31]);
			end
			4'b0010 :// SLL
			 begin 
				result = b << shamt;
				if (shamt != 0) cout = b[32 - shamt];
			end
			4'b0011 :// SRL
			begin 
				result = $unsigned(b) >> shamt;
				if (shamt != 0) cout = b[shamt - 1];
			end
			4'b0100 :// SRA
			begin 
				result = b >>> shamt;
				if (shamt != 0) cout = b[shamt - 1];
			end	
			4'b0101 : result = a & b;  //AND
			4'b0110 : result = a | b; //OR
			4'b0111 : result = a ^ b; //XOR
			default : 
			begin
				result = 0;
				cout = 0;
				over = 0;
			end
		endcase
	end

endmodule 