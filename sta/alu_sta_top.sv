`timescale 1ns / 1ps

module alu_sta_top (
    input logic clk,
    input logic [31:0] a_in,
    input logic [31:0] b_in,
    input logic [4:0] shamt_in,
    input logic [3:0] op_in,
    output logic [31:0] result_out,
    output logic cout_out,
    output logic over_out,
    output logic zero_out,
    output logic neg_out
);

    logic [31:0] a_reg;
    logic [31:0] b_reg;
    logic [3:0] op_reg;
    
    logic [31:0] result_reg;
    logic cout_reg;
    logic over_reg;
    logic zero_reg;
    logic neg_reg;
    
     always_ff @(posedge clk) begin
        a_reg <= a_in;
        b_reg <= b_in;
        op_reg <= op_in;
     end

    alu u_alu (
        .a(a_reg), 
        .b(b_reg), 
        .shamt(5'b00000), 
        .op(op_reg),
        .result(result_reg), 
        .cout(cout_reg), 
        .zero(zero_reg), 
        .over(over_reg), 
        .neg(neg_reg)
    );

    always_ff @(posedge clk) begin
        result_out <= result_reg;
        cout_out <= cout_reg;
        over_out <= over_reg;
        zero_out <= zero_reg;
        neg_out <= neg_reg;
    end
    
    
endmodule
