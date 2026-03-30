module general_reg(
	input logic clk,
	input logic [3:0] dbg_addr,
	input logic up_reg_sel,
	input logic [4:0] rs_addr,
	input logic [4:0] rt_addr,
	input logic [4:0] rd_addr,
	input logic [31:0] data,
	input logic reg_we,
	output logic [15:0] dbg_data,
   output logic [31:0] rs_data,
   output logic [31:0] rt_data
);

    
   logic [31:0] Register [15:0];
	initial begin
      integer i;
      for (i = 0; i < 16; i = i + 1)
         Register[i] = 32'd0;

      Register[1] = 32'd30;
      Register[2] = 32'd7;
	end

    
	always_comb begin
	    if (up_reg_sel) dbg_data = (dbg_addr == 0) ? 0 : Register[dbg_addr][31:16];
	    else dbg_data = (dbg_addr == 0) ? 0 : Register[dbg_addr][15:0];
	    
        rs_data = (rs_addr==0) ? 0 : Register[rs_addr];
        rt_data = (rt_addr==0) ? 0 : Register[rt_addr];
    end
    
    always_ff @ (posedge clk) begin
        if (reg_we && rd_addr != 0)
            Register[rd_addr] <= data; 
    end
	
endmodule
		