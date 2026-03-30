module multi_sta_top (
    input logic clk,
    input logic rst_n,
    input logic lo_hi_in,
    input logic valid_in_in,
    input logic signed [31:0] a_in,
    input logic signed [31:0] b_in,
    output logic signed [31:0] result_out,
    output logic valid_out_out
);

    logic lo_hi_reg;
    logic valid_in_reg;
    logic [31:0] a_reg;
    logic [31:0] b_reg;
    
    logic [31:0] result_reg;
    logic valid_out_reg;
    
     always_ff @(posedge clk) begin
        a_reg <= a_in;
        b_reg <= b_in;
        lo_hi_reg <= lo_hi_in;
        valid_in_reg <= valid_in_in;
     end

    multiplier_blk u_mul (
        .clk(clk),
        .rst_n(rst_n),
        .lo_hi(lo_hi_reg),
        .valid_in(valid_in_reg),
        .a(a_reg), 
        .b(b_reg), 
        .result(result_reg), 
        .valid_out(valid_out_reg)
    );

    always_ff @(posedge clk) begin
        result_out <= result_reg;
        valid_out_out   <= valid_out_reg;
    end
    
    
endmodule
