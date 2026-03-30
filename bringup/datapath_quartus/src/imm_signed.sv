module imm_signed(
    input logic [15:0] imm_val,
    input logic upbound,
    output logic signed [31:0] b_val
);

    always_comb begin
        if (upbound)
            b_val = {imm_val, 16'b0};             
        else 
            b_val = {{16{imm_val[15]}}, imm_val};   
    
    end

endmodule
