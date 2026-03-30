module cpu_sta_top(
    input logic clk,
    input logic rst_n,
    input logic mode_in,
    input logic [1:0] dbg_sel,
    output logic [31:0] dbg_bus_q
);

    logic mode_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) mode_q <= 1'b0;
        else mode_q <= mode_in;
    end

    logic [31:0] PC_dbg_w;
    logic [31:0] IR_dbg_w;
    logic [31:0] ALUOut_dbg_w;
    logic [31:0] status_reg_w;

    logic [3:0] REG_addr_dbg;
    logic reg_sel_dbg;
    logic [15:0] REG_dbg_w;

    assign REG_addr_dbg = 4'd0;
    assign reg_sel_dbg = 1'b0;

    cpu_top DUT(
        .clk(clk),
        .rst_n(rst_n),
        .mode(mode_q),
        .REG_addr_dbg(REG_addr_dbg),
        .reg_sel_dbg(reg_sel_dbg),
        .PC_dbg(PC_dbg_w),
        .IR_dbg(IR_dbg_w),
        .ALUOut_dbg(ALUOut_dbg_w),
        .status_reg(status_reg_w),
        .REG_dbg(REG_dbg_w)
    );

    logic [31:0] dbg_bus_w;

    always_comb begin
        unique case(dbg_sel)
            2'b00: dbg_bus_w = PC_dbg_w;
            2'b01: dbg_bus_w = IR_dbg_w;
            2'b10: dbg_bus_w = ALUOut_dbg_w;
            2'b11: dbg_bus_w = status_reg_w;
            default: dbg_bus_w = PC_dbg_w;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) dbg_bus_q <= 32'd0;
        else dbg_bus_q <= dbg_bus_w;
    end

endmodule
