module general_reg(
	input logic clk,
	input logic [3:0] dbg_addr,
	input logic [4:0] rs_addr,
	input logic [4:0] rt_addr,
	input logic [4:0] rd_addr,
	input logic [31:0] data,
	input logic reg_we,
	output logic [31:0] dbg_data,
    output logic [31:0] rs_data,
    output logic [31:0] rt_data
);

    
   logic [31:0] Register [15:0];
    
	assign dbg_data = Register[dbg_addr];
	    
    
	always_comb begin
        rs_data = (rs_addr==0) ? 0 : Register[rs_addr];
        rt_data = (rt_addr==0) ? 0 : Register[rt_addr];
    end
    
    always_ff @ (posedge clk) begin
        if (reg_we && rd_addr != 0)
            Register[rd_addr] <= data; 
    end
	
endmodule
		