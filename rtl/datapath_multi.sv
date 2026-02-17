module datapath_multi (
    // Clock / reset / mode
    input logic clk,
    input logic rst_n,
    input logic mode,

    // Instruction memory interface
    output logic [12:0] imem_addr,
    input logic [31:0] imem_rdata,

    // Data memory interface
    output logic [12:0] dmem_addr,     
    output logic [31:0] dmem_wdata,
    output logic dmem_wen, // 0:read, 1:write
    output logic dmem_en,
    input logic [31:0] dmem_rdata,

    // Decoded fields
    input logic [4:0] rs_addr,
    input logic [4:0] rt_addr,
    input logic [4:0] rd_addr,
    input logic [15:0] imm_val,
    input logic upbound,

    // PC / IR controls
    input logic clr_pc,
    input logic ld_pc,
    input logic [1:0] pc_sel, // 0:PC+4, 1:branch, 2:JR(rs), 3:jump_target

    input logic clr_ir,
    input logic ld_ir,

    // Internal latch controls
    input logic ld_a,
    input logic ld_b,
    input logic ld_aluout,
    input logic ld_mdr,

    // Execute controls
    input logic alu_b_sel, // 0:B, 1:imm_ext
    input logic use_slt,
    input logic [3:0] alu_op,
    input logic [4:0] shamt,

    input logic mul_valid_in,
    input logic lo_hi,
    input logic use_mul, //  0:ALU result, 1:multiplier result
    output logic mul_valid_out,

    // Branch control
    input logic br_sel, // 0:BNE, 1:EQ 

    // Memory op control (from controller)
    input logic mem_en_ctrl,
    input logic mem_wen_ctrl, // 0:load, 1:store

    // Load/store size + sign
    input logic [1:0] mem_size,
    input logic mem_unsigned,

    // Reg writeback control
    input logic reg_we,
    input logic [1:0] waddr_sel, // 0:rd, 1:rt, 2:link(R15)
    input logic [1:0] wdata_sel, // 0:ALUOut, 1:LoadData, 2:PC+4, 3:StatusReg

    // Status flags control
    input logic [3:0] clr_flag,
    input logic flag_en,

    // Debug / flags
    input logic up_reg_sel,
    input logic [3:0] dbg_reg_addr,
	output logic [15:0] dbg_reg_data,
    output logic [31:0] IR_dbg,
    output logic [31:0] PC_dbg,
    output logic [31:0] ALUOut_dbg,
    output logic [31:0] status_reg,

    output logic zero,
    output logic neg,
    output logic cout,
    output logic over
);

    logic [31:0] PC_q;
    logic [31:0] pc_d;
    logic [31:0] IR;

    logic signed [31:0] A_q;
    logic signed [31:0] B_q;
    logic signed [31:0] alu_result;
    logic [31:0] ALUOut;
    logic [31:0] register_mem;  

    assign PC_dbg = PC_q;
    assign IR_dbg = IR;
    assign ALUOut_dbg = ALUOut;

    assign imem_addr = PC_q[12:0];

    program_count PC0 (
        .clk (clk),
        .clr (clr_pc),
        .ld (ld_pc),
        .d (pc_d),
        .q (PC_q)
    );

    instr_reg IR0 (
        .clk (clk),
        .clr_ir (clr_ir),
        .ld_ir (ld_ir),
        .instr_data (imem_rdata),
        .IR (IR)
    );


    logic [25:0] jump_target26;
    assign jump_target26 = IR[25:0];

    logic signed [31:0] imm_ext;
    imm_signed IMM0 (
        .imm_val (imm_val),
        .upbound (upbound),
        .b_val (imm_ext)
    );

    logic [31:0] pc_plus4;
    assign pc_plus4 = PC_q + 4;

    logic [31:0] branch_target;
    assign branch_target = {14'b0, imm_val, 2'b00};

    logic [4:0] rs_s, rt_s, wa_s;
    assign rs_s = rs_addr[4:0];
    assign rt_s = rt_addr[4:0];

    localparam logic [4:0] LINK_REG = 5'd15;

    always_comb begin
        unique case (waddr_sel)
            2'd0: wa_s = rd_addr[4:0];
            2'd1: wa_s = rt_addr[4:0];
            2'd2: wa_s = LINK_REG;
            default: wa_s = rd_addr[4:0];
        endcase
    end

    logic [31:0] rs_data_u, rt_data_u;
    logic [31:0] rf_wdata;

    general_reg RF0 (
        .clk (clk),
        .dbg_addr(dbg_reg_addr),
	    .up_reg_sel(up_reg_sel),
        .rs_addr (rs_s),
        .rt_addr (rt_s),
        .rd_addr (wa_s),
        .data (rf_wdata),
        .reg_we (reg_we),
        .dbg_data(dbg_reg_data),
        .rs_data (rs_data_u),
        .rt_data (rt_data_u)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_q <= 32'sd0;
            B_q <= 32'sd0;
        end else begin
            if (ld_a) A_q <= $signed(rs_data_u);
            if (ld_b) B_q <= $signed(rt_data_u);
        end
    end

    logic signed [31:0] alu_b_in;
    assign alu_b_in = (alu_b_sel) ? imm_ext : B_q;

    alu ALU0 (
        .a (A_q),
        .b (alu_b_in),
        .shamt (shamt),
        .op (alu_op),
        .result (alu_result),
        .cout (cout),
        .zero (zero),
        .over (over),
        .neg (neg)
    );

    logic signed [31:0] mul_result;

    multiplier_blk MUL0 (
        .clk (clk),
        .rst_n (rst_n),
        .lo_hi (lo_hi),
        .valid_in (mul_valid_in),
        .a (A_q),
        .b (B_q),
        .result (mul_result),
        .valid_out (mul_valid_out)
    );

    logic signed [31:0] exec_result;
    logic slt_bit;
    logic signed [31:0] alu_or_slt;

    always_comb begin
        slt_bit = (neg ^ over);
        alu_or_slt = use_slt ? $signed({31'b0, slt_bit}) : alu_result;
        exec_result = use_mul ? mul_result : alu_or_slt;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) ALUOut <= 32'd0;
        else if (ld_aluout) ALUOut <= exec_result;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) register_mem <= 32'd0;
        else if (ld_mdr) register_mem <= dmem_rdata;
    end

    assign dmem_en = mem_en_ctrl;
    assign dmem_wen = mem_wen_ctrl;

    assign dmem_addr = ALUOut[12:0];

    logic [1:0] byte_off;
    logic half_sel;

    assign byte_off = ALUOut[1:0];
    assign half_sel = ALUOut[1];

    logic signed [7:0] load_b;
    logic signed [15:0] load_h;
    logic signed [31:0] load_data;

    always_comb begin
        load_b = register_mem[7:0];
        load_h = register_mem[15:0];

        case (byte_off)
            2'b00: load_b = register_mem[7:0];
            2'b01: load_b = register_mem[15:8];
            2'b10: load_b = register_mem[23:16];
            2'b11: load_b = register_mem[31:24];
            default: load_b = register_mem[7:0];
        endcase

        load_h = half_sel ? register_mem[31:16] : register_mem[15:0];

        unique case (mem_size)
            2'b00: load_data = mem_unsigned ? {24'b0, $unsigned(load_b)} : {{24{load_b[7]}}, load_b};
            2'b01: load_data = mem_unsigned ? {16'b0, $unsigned(load_h)} : {{16{load_h[15]}}, load_h};
            2'b10: load_data = register_mem;
            default: load_data = register_mem;
        endcase
    end

    logic [31:0] store_word;

    always_comb begin
        store_word = B_q;

        unique case (mem_size)
            2'b10: store_word = B_q;
            2'b00: begin
                case (byte_off)
                    2'b00: store_word = {register_mem[31:8],  B_q[7:0]};
                    2'b01: store_word = {register_mem[31:16], B_q[7:0], register_mem[7:0]};
                    2'b10: store_word = {register_mem[31:24], B_q[7:0], register_mem[15:0]};
                    2'b11: store_word = {B_q[7:0], register_mem[23:0]};
                    default: store_word = {register_mem[31:8], B_q[7:0]};
                endcase
            end
            2'b01: begin
                store_word = half_sel ? {B_q[15:0], register_mem[15:0]} : {register_mem[31:16], B_q[15:0]};
            end
            default: store_word = B_q;
        endcase
    end

    assign dmem_wdata = store_word;

    status_flag SF0 (
        .clk (clk),
        .rst_n (rst_n),
        .clr_flag (clr_flag),
        .flag_en (flag_en),
        .flag_val ({neg, zero, cout, over}),
        .mode (mode),
        .status_reg (status_reg)
    );

    always_comb begin
        unique case (wdata_sel)
            2'd0: rf_wdata = ALUOut;
            2'd1: rf_wdata = load_data;
            2'd2: rf_wdata = pc_plus4;
            2'd3: rf_wdata = status_reg;
            default: rf_wdata = ALUOut;
        endcase
    end

    logic take_branch;
    assign take_branch = br_sel ? zero : ~zero; 
    always_comb begin
        unique case (pc_sel)
            2'd0: pc_d = pc_plus4;
            2'd1: pc_d = take_branch ? branch_target : pc_plus4;
            2'd2: pc_d = $unsigned(A_q);
            2'd3: pc_d = {jump_target26, 2'b00};
            default: pc_d = pc_plus4;
        endcase
    end

endmodule
