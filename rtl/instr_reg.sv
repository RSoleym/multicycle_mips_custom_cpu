module instr_reg(
    input logic clk,
    input logic clr_ir,
    input logic ld_ir,
    input logic [31:0] instr_data,
    output logic [31:0] IR
);

    always_ff @(posedge clk) begin
        if (clr_ir)
            IR <= 0;
        else if (ld_ir)
            IR <= instr_data;
    end
    
endmodule
