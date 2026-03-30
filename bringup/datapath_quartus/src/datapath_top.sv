module datapath_top (
    input logic clk,
    input logic rst_n_in,
    input logic mode,
	 
    input logic clr_pc,
    input logic ld_pc,
    input logic [1:0]  pc_sel,

    input logic clr_ir,
    input logic ld_ir,

    input logic ld_a,
    input logic ld_b,
    input logic ld_aluout,
    input logic ld_mdr,

    input logic alu_b_sel,
    input logic use_slt,
    input logic [3:0] alu_op,

    input logic mul_valid_in,
    input logic lo_hi,
    input logic use_mul,

    input logic br_sel,

    input logic mem_en_ctrl,
    input logic mem_wen_ctrl,
    input logic [1:0] mem_size,
    input logic mem_unsigned,

    input logic reg_we,
    input logic [1:0] waddr_sel,
    input logic [1:0] wdata_sel,

    input logic [3:0] clr_flag,
    input logic flag_en,
    input logic upbound,

    input logic up_reg_sel,
    input logic [3:0] dbg_reg_addr,

    // choose one of 30 example instructions
    input  logic [4:0]  instr_sel,

    // choose what appears on debug_bus
    // 0=PC, 1=IR, 2=ALUOut, 3=Status, 4=InstrWord
    // 5=DMemAddr, 6=DMemWData, 7=DMemRData
    // 8=rs/rt/rd packed, 9=imm
    input  logic [3:0]  debug_sel,

    // reduced outputs
    output logic [31:0] debug_bus,
    output logic [15:0] dbg_reg_data,

    output logic zero,
    output logic neg,
    output logic cout,
    output logic over,

    output logic dmem_en,
    output logic dmem_wen,
    output logic mul_valid_out
);
	
	 assign rst_n = ~rst_n_in;

    localparam logic [5:0] OP_RTYPE = 6'b000000;
    localparam logic [5:0] OP_JMP   = 6'b000001;
    localparam logic [5:0] OP_JAL   = 6'b000011;
    localparam logic [5:0] OP_BEQ   = 6'b000100;
    localparam logic [5:0] OP_BNE   = 6'b000101;
    localparam logic [5:0] OP_LW    = 6'b000110;
    localparam logic [5:0] OP_SW    = 6'b000111;
    localparam logic [5:0] OP_LB    = 6'b001000;
    localparam logic [5:0] OP_LBU   = 6'b001001;
    localparam logic [5:0] OP_SB    = 6'b001010;
    localparam logic [5:0] OP_LH    = 6'b001011;
    localparam logic [5:0] OP_LHU   = 6'b001100;
    localparam logic [5:0] OP_SH    = 6'b001101;
    localparam logic [5:0] OP_LUI   = 6'b001110;
    localparam logic [5:0] OP_SLTI  = 6'b001111;
    localparam logic [5:0] OP_ADDI  = 6'b010000;
    localparam logic [5:0] OP_ANDI  = 6'b010001;
    localparam logic [5:0] OP_ORI   = 6'b010010;
    localparam logic [5:0] OP_XORI  = 6'b010011;

    localparam logic [5:0] FN_JR    = 6'b000010;
    localparam logic [5:0] FN_SLT   = 6'b001111;
    localparam logic [5:0] FN_ADD   = 6'b010000;
    localparam logic [5:0] FN_AND   = 6'b010001;
    localparam logic [5:0] FN_OR    = 6'b010010;
    localparam logic [5:0] FN_XOR   = 6'b010011;
    localparam logic [5:0] FN_SUB   = 6'b010100;
    localparam logic [5:0] FN_SLL   = 6'b010101;
    localparam logic [5:0] FN_SRL   = 6'b010110;
    localparam logic [5:0] FN_SRA   = 6'b010111;
    localparam logic [5:0] FN_MULLO = 6'b011000;
    localparam logic [5:0] FN_MULHI = 6'b011001;

    localparam logic [4:0] R0 = 5'd0;
    localparam logic [4:0] R1 = 5'd1;
    localparam logic [4:0] R2 = 5'd2;
    localparam logic [4:0] R3 = 5'd3;

    function automatic logic [31:0] enc_r (
        input logic [4:0] rs,
        input logic [4:0] rt,
        input logic [4:0] rd,
        input logic [4:0] shamt,
        input logic [5:0] funct
    );
        enc_r = {OP_RTYPE, rs, rt, rd, shamt, funct};
    endfunction

    function automatic logic [31:0] enc_i (
        input logic [5:0] opcode,
        input logic [4:0] rs,
        input logic [4:0] rt,
        input logic [15:0] imm
    );
        enc_i = {opcode, rs, rt, imm};
    endfunction

    function automatic logic [31:0] enc_j (
        input logic [5:0] opcode,
        input logic [25:0] target
    );
        enc_j = {opcode, target};
    endfunction

    logic [31:0] instr_word;
    always_comb begin
        unique case (instr_sel)
            5'd0:  instr_word = enc_r(R1, R2, R3, 5'd0, FN_SLT);
            5'd1:  instr_word = enc_r(R1, R2, R3, 5'd0, FN_ADD);
            5'd2:  instr_word = enc_r(R1, R2, R3, 5'd0, FN_AND);
            5'd3:  instr_word = enc_r(R1, R2, R3, 5'd0, FN_OR);
            5'd4:  instr_word = enc_r(R1, R2, R3, 5'd0, FN_XOR);
            5'd5:  instr_word = enc_r(R1, R2, R3, 5'd0, FN_SUB);
            5'd6:  instr_word = enc_r(R1, R2, R3, 5'd2, FN_SLL);
            5'd7:  instr_word = enc_r(R1, R2, R3, 5'd2, FN_SRL);
            5'd8:  instr_word = enc_r(R1, R2, R3, 5'd2, FN_SRA);
            5'd9:  instr_word = enc_r(R1, R2, R3, 5'd0, FN_MULLO);
            5'd10: instr_word = enc_r(R1, R2, R3, 5'd0, FN_MULHI);
            5'd11: instr_word = enc_r(R1, R0, R0, 5'd0, FN_JR);
            5'd12: instr_word = enc_j(OP_JAL, 26'd8);
            5'd13: instr_word = enc_i(OP_BEQ,  R1, R2, 16'd1);
            5'd14: instr_word = enc_i(OP_BNE,  R1, R2, 16'd1);
            5'd15: instr_word = enc_i(OP_LW,   R1, R3, 16'd4);
            5'd16: instr_word = enc_i(OP_SW,   R1, R2, 16'd8);
            5'd17: instr_word = enc_i(OP_LB,   R1, R3, 16'd4);
            5'd18: instr_word = enc_i(OP_LBU,  R1, R3, 16'd4);
            5'd19: instr_word = enc_i(OP_SB,   R1, R2, 16'd8);
            5'd20: instr_word = enc_i(OP_LH,   R1, R3, 16'd4);
            5'd21: instr_word = enc_i(OP_LHU,  R1, R3, 16'd4);
            5'd22: instr_word = enc_i(OP_SH,   R1, R2, 16'd8);
            5'd23: instr_word = enc_i(OP_LUI,  R0, R3, 16'h1234);
            5'd24: instr_word = enc_i(OP_SLTI, R1, R3, 16'd20);
            5'd25: instr_word = enc_i(OP_ADDI, R1, R3, 16'd5);
            5'd26: instr_word = enc_i(OP_ANDI, R1, R3, 16'h000F);
            5'd27: instr_word = enc_i(OP_ORI,  R1, R3, 16'h000F);
            5'd28: instr_word = enc_i(OP_XORI, R1, R3, 16'h000F);
            5'd29: instr_word = enc_j(OP_JMP,  26'd16);
            default: instr_word = 32'd0;
        endcase
    end

    logic [31:0] IR_dbg, PC_dbg, ALUOut_dbg, status_reg;

    // Decode from the LATCHED IR, not directly from instr_word
    logic [4:0]  rs_addr_i, rt_addr_i, rd_addr_i;
    logic [15:0] imm_val_i;
    logic [4:0]  shamt_i;

    assign rs_addr_i = IR_dbg[25:21];
    assign rt_addr_i = IR_dbg[20:16];
    assign rd_addr_i = IR_dbg[15:11];
    assign imm_val_i = IR_dbg[15:0];
    assign shamt_i   = IR_dbg[10:6];

    logic [31:0] dmem [0:255];
    logic [31:0] dmem_rdata;
    logic [12:0] imem_addr_int;
    logic [12:0] dmem_addr_int;
    logic [31:0] dmem_wdata_int;

    initial begin
        integer i;
        for (i = 0; i < 256; i = i + 1)
            dmem[i] = 32'd0;

        dmem[8'd34] = 32'h1234_ABCD;
        dmem[8'd38] = 32'hAAAA_5555;
    end

    assign dmem_rdata = dmem[dmem_addr_int[7:0]];

    always_ff @(posedge clk) begin
        if (dmem_en && dmem_wen)
            dmem[dmem_addr_int[7:0]] <= dmem_wdata_int;
    end

    datapath DP0 (
        .clk (clk),
        .rst_n (rst_n),
        .mode (mode),

        .imem_addr (imem_addr_int),
        .imem_rdata (instr_word),

        .dmem_addr (dmem_addr_int),
        .dmem_wdata (dmem_wdata_int),
        .dmem_wen (dmem_wen),
        .dmem_en (dmem_en),
        .dmem_rdata (dmem_rdata),

        .rs_addr (rs_addr_i),
        .rt_addr (rt_addr_i),
        .rd_addr (rd_addr_i),
        .imm_val (imm_val_i),
        .upbound (upbound),

        .clr_pc (clr_pc),
        .ld_pc (ld_pc),
        .pc_sel (pc_sel),
 
        .clr_ir (clr_ir),
        .ld_ir (ld_ir),

        .ld_a (ld_a),
        .ld_b (ld_b),
        .ld_aluout (ld_aluout),
        .ld_mdr (ld_mdr),

        .alu_b_sel (alu_b_sel),
        .use_slt (use_slt),
        .alu_op (alu_op),
        .shamt (shamt_i),

        .mul_valid_in (mul_valid_in),
        .lo_hi (lo_hi),
        .use_mul (use_mul),
        .mul_valid_out (mul_valid_out),

        .br_sel (br_sel),

        .mem_en_ctrl (mem_en_ctrl),
        .mem_wen_ctrl (mem_wen_ctrl),
        .mem_size (mem_size),
        .mem_unsigned (mem_unsigned),

        .reg_we (reg_we),
        .waddr_sel (waddr_sel),
        .wdata_sel (wdata_sel),

        .clr_flag (clr_flag),
        .flag_en (flag_en),

        .up_reg_sel (up_reg_sel),
        .dbg_reg_addr (dbg_reg_addr),
        .dbg_reg_data (dbg_reg_data),
        .IR_dbg (IR_dbg),
        .PC_dbg (PC_dbg),
        .ALUOut_dbg (ALUOut_dbg),
        .status_reg (status_reg),

        .zero (zero),
        .neg (neg),
        .cout (cout),
        .over (over)
    );

    always_comb begin
        unique case (debug_sel)
            4'd0: debug_bus = PC_dbg;
            4'd1: debug_bus = IR_dbg;
            4'd2: debug_bus = ALUOut_dbg;
            4'd3: debug_bus = status_reg;
            4'd4: debug_bus = instr_word;
            4'd5: debug_bus = {19'd0, dmem_addr_int};
            4'd6: debug_bus = dmem_wdata_int;
            4'd7: debug_bus = dmem_rdata;
            4'd8: debug_bus = {17'd0, rs_addr_i, rt_addr_i, rd_addr_i};
            4'd9: debug_bus = {16'd0, imm_val_i};
            default: debug_bus = 32'd0;
        endcase
    end

endmodule