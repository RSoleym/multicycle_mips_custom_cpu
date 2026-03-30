module control_unit_multi (
    // Clock / reset / mode
    input logic clk,
    input logic rst_n,
    input logic mode,

    // From datapath
    input logic [31:0] IR,
    input logic zero,
    input logic over,
    input logic carry,
    input logic neg,
    input logic mul_valid_out,

    // Decoded fields
    output logic [4:0] rs_addr,
    output logic [4:0] rt_addr,
    output logic [4:0] rd_addr,
    output logic [15:0]imm_val,
    output logic upbound,

    // PC / IR controls
    output logic clr_pc,
    output logic ld_pc,
    output logic [1:0] pc_sel,
    output logic clr_ir,
    output logic ld_ir,

    // Internal latch controls
    output logic ld_a,
    output logic ld_b,
    output logic ld_aluout,
    output logic ld_mdr,

    // Execute controls
    output logic alu_b_sel,
    output logic [3:0] alu_op,
    output logic use_slt,
    output logic [4:0] shamt,

    output logic mul_valid_in,
    output logic lo_hi,
    output logic use_mul,

    // Branch control
    output logic br_sel,

    // Memory controls
    output logic mem_en_ctrl,
    output logic mem_wen_ctrl, 
    output logic [1:0] mem_size,
    output logic mem_unsigned,

    // Reg writeback controls
    output logic reg_we,
    output logic [1:0] waddr_sel,
    output logic [1:0] wdata_sel,

    // Status flags controls
    output logic [3:0] clr_flag,
    output logic flag_en
);

    // Field decode 
    logic [5:0] opcode, funct;
    logic [4:0] shamt_dec;

    assign opcode = IR[31:26];
    assign rs_addr = IR[25:21];
    assign rt_addr = IR[20:16];
    assign rd_addr = IR[15:11];
    assign shamt_dec = IR[10:6];
    assign funct = IR[5:0];
    assign imm_val = IR[15:0];

    // ISA opcodes
    localparam logic [5:0] OP_RTYPE = 6'b000000;

    localparam logic [5:0] OP_JMP = 6'b000001;
    localparam logic [5:0] OP_JAL = 6'b000011;

    localparam logic [5:0] OP_BEQ = 6'b000100;
    localparam logic [5:0] OP_BNE = 6'b000101;

    localparam logic [5:0] OP_LW = 6'b000110;
    localparam logic [5:0] OP_SW = 6'b000111;

    localparam logic [5:0] OP_LB = 6'b001000;
    localparam logic [5:0] OP_LBU = 6'b001001;
    localparam logic [5:0] OP_SB = 6'b001010;

    localparam logic [5:0] OP_LH = 6'b001011;
    localparam logic [5:0] OP_LHU = 6'b001100;
    localparam logic [5:0] OP_SH = 6'b001101;

    localparam logic [5:0] OP_LUI = 6'b001110;
    localparam logic [5:0] OP_SLTI = 6'b001111;
    localparam logic [5:0] OP_ADDI = 6'b010000;
    localparam logic [5:0] OP_ANDI = 6'b010001;
    localparam logic [5:0] OP_ORI = 6'b010010;
    localparam logic [5:0] OP_XORI = 6'b010011;

    localparam logic [5:0] FN_JR = 6'b000010;

    localparam logic [5:0] FN_SLT = 6'b001111;
    localparam logic [5:0] FN_ADD = 6'b010000;
    localparam logic [5:0] FN_AND = 6'b010001;
    localparam logic [5:0] FN_OR = 6'b010010;
    localparam logic [5:0] FN_XOR = 6'b010011;
    localparam logic [5:0] FN_SUB = 6'b010100;

    localparam logic [5:0] FN_SLL = 6'b010101;
    localparam logic [5:0] FN_SRL = 6'b010110;
    localparam logic [5:0] FN_SRA = 6'b010111;

    localparam logic [5:0] FN_MULLO = 6'b011000;
    localparam logic [5:0] FN_MULHI = 6'b011001;

    // ALU control
    localparam logic [3:0] ALU_ADD = 4'b0000;
    localparam logic [3:0] ALU_SUB = 4'b0001;
    localparam logic [3:0] ALU_SLL = 4'b0010;
    localparam logic [3:0] ALU_SRL = 4'b0011;
    localparam logic [3:0] ALU_SRA = 4'b0100;
    localparam logic [3:0] ALU_AND = 4'b0101;
    localparam logic [3:0] ALU_OR = 4'b0110;
    localparam logic [3:0] ALU_XOR = 4'b0111;

    // Instruction class flags
    logic is_rtype, is_nop;
    logic is_jmp, is_jal, is_branch, is_beq, is_bne, is_jr;
    logic is_alu_imm;
    logic is_load, is_store, is_store_rmw;
    logic is_mul, is_mul_lo, is_mul_hi;
    logic is_slt, is_slti;

    assign is_rtype = (opcode == OP_RTYPE);
    assign is_nop = (IR == 32'd0);

    assign is_jmp = (opcode == OP_JMP);
    assign is_jal = (opcode == OP_JAL);

    assign is_beq = (opcode == OP_BEQ);
    assign is_bne = (opcode == OP_BNE);
    assign is_branch = is_beq | is_bne;

    assign is_jr = is_rtype && (funct == FN_JR);

    assign is_load = (opcode == OP_LW) | (opcode == OP_LB)  | (opcode == OP_LBU) | (opcode == OP_LH)  | (opcode == OP_LHU);

    assign is_store = (opcode == OP_SW) | (opcode == OP_SB)  | (opcode == OP_SH);

    assign is_store_rmw = (opcode == OP_SB) | (opcode == OP_SH);

    assign is_alu_imm = (opcode == OP_ADDI) | (opcode == OP_ANDI) | (opcode == OP_ORI) | (opcode == OP_XORI) | (opcode == OP_LUI) | (opcode == OP_SLTI);

    assign is_mul_lo = is_rtype && (funct == FN_MULLO);
    assign is_mul_hi = is_rtype && (funct == FN_MULHI);
    assign is_mul = is_mul_lo | is_mul_hi;

    assign is_slt = is_rtype && (funct == FN_SLT);
    assign is_slti = (opcode == OP_SLTI);

    assign upbound = (opcode == OP_LUI);

    always_comb begin
        mem_size = 2'b10;
        mem_unsigned = 1'b0;

        unique case (opcode)
            OP_LB: begin mem_size = 2'b00; mem_unsigned = 1'b0; end
            OP_LBU: begin mem_size = 2'b00; mem_unsigned = 1'b1; end
            OP_LH: begin mem_size = 2'b01; mem_unsigned = 1'b0; end
            OP_LHU: begin mem_size = 2'b01; mem_unsigned = 1'b1; end
            OP_LW: begin mem_size = 2'b10; mem_unsigned = 1'b0; end

            OP_SB: begin mem_size = 2'b00; end
            OP_SH: begin mem_size = 2'b01; end
            OP_SW: begin mem_size = 2'b10; end
            default: begin end
        endcase
    end

    typedef enum logic [4:0] {
        S_RESET,
        S_IF,
        S_ID,
        S_EX_R,
        S_EX_I,
        S_EX_ADDR,
        S_EX_BR,
        S_JUMP,
        S_MEM_RD1,
        S_MEM_RD2,
        S_WB_LD,
        S_MEM_WR,
        S_RMW_RD1,
        S_RMW_RD2,
        S_RMW_WR,
        S_MUL_START,
        S_MUL_WAIT1,
        S_MUL_CAP,
        S_WB_R
    } state_t;

    state_t state, state_n;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= S_RESET;
        else state <= state_n;
    end

    always_comb begin
        clr_pc = 1'b0;
        ld_pc = 1'b0;
        pc_sel = 2'd0;

        clr_ir = 1'b0;
        ld_ir = 1'b0;

        ld_a = 1'b0;
        ld_b = 1'b0;
        ld_aluout = 1'b0;
        use_slt = 1'b0;
        ld_mdr = 1'b0;

        alu_b_sel = 1'b0;
        alu_op = ALU_ADD;
        shamt = 5'd0;

        mul_valid_in = 1'b0;
        lo_hi = 1'b0;
        use_mul = 1'b0;

        br_sel = 1'b0;

        mem_en_ctrl = 1'b0;
        mem_wen_ctrl = 1'b0;

        reg_we = 1'b0;
        waddr_sel = 2'd0;
        wdata_sel = 2'd0;

        clr_flag = 4'b0000;
        flag_en = 1'b0;

        state_n = state;

        unique case (state)
            S_RESET: begin
                clr_pc  = 1'b1;
                clr_ir  = 1'b1;
                state_n = S_IF;
            end
            
            S_IF: begin
                ld_ir   = 1'b1;
                state_n = S_ID;
            end

            S_ID: begin
                ld_a = 1'b1;
                ld_b = 1'b1;
                if (is_nop) begin
                    ld_pc = 1'b1;
                    pc_sel = 2'd0;
                    state_n = S_IF;                    
                end else if (is_jmp | is_jal) state_n = S_JUMP;
                else if (is_jr | is_branch) state_n = S_EX_BR;
                else if (is_load | is_store) state_n = S_EX_ADDR;
                else if (is_mul) state_n = S_MUL_START;
                else if (is_alu_imm) state_n = S_EX_I;
                else if (is_rtype) state_n = S_EX_R;
                else begin
                    ld_pc = 1'b1;
                    pc_sel = 2'd0;
                    state_n = S_IF;
                end
            end

            S_EX_R: begin
                alu_b_sel = 1'b0;
                shamt = shamt_dec;
                unique case (funct)
                    FN_ADD: alu_op = ALU_ADD;
                    FN_SUB: alu_op = ALU_SUB;
                    FN_AND: alu_op = ALU_AND;
                    FN_OR : alu_op = ALU_OR;
                    FN_XOR: alu_op = ALU_XOR;
                    FN_SLL: alu_op = ALU_SLL;
                    FN_SRL: alu_op = ALU_SRL;
                    FN_SRA: alu_op = ALU_SRA;
                    FN_SLT: begin
                        alu_op = ALU_SUB;
                        use_slt = 1'b1; 
                    end
                    default: alu_op = ALU_ADD;
                endcase
                use_mul = 1'b0;
                ld_aluout = 1'b1;
                if (!(funct == FN_SLT)) flag_en = 1'b1;
                state_n = S_WB_R;
            end

            S_EX_I: begin
                alu_b_sel = 1'b1;
                shamt = 5'd0;
                unique case (opcode)
                    OP_ADDI: alu_op = ALU_ADD;
                    OP_ANDI: alu_op = ALU_AND;
                    OP_ORI : alu_op = ALU_OR;
                    OP_XORI: alu_op = ALU_XOR;
                    OP_LUI : alu_op = ALU_ADD;
                    OP_SLTI: begin
                        alu_op = ALU_SUB;
                        use_slt = 1'b1;
                    end
                    default: alu_op = ALU_ADD;
                endcase
                use_mul = 1'b0;
                ld_aluout = 1'b1;
                if (opcode != OP_SLTI) flag_en = 1'b1;
                state_n = S_WB_R;
            end

            S_EX_BR: begin
                if (is_jr) begin
                    ld_pc = 1'b1;
                    pc_sel = 2'd2;
                    state_n = S_IF;
                end else begin
                    alu_b_sel = 1'b0;
                    alu_op = ALU_SUB;
                    br_sel = is_beq ? 1'b1 : 1'b0;
                    ld_pc = 1'b1;
                    pc_sel = 2'd1;
                    state_n = S_IF;
                end
            end
            
            S_JUMP: begin
                ld_pc = 1'b1;
                pc_sel = 2'd3;
                if (is_jal) begin
                    reg_we = 1'b1;
                    waddr_sel = 2'd2; // link R15
                    wdata_sel = 2'd2; // PC+4
                end
                state_n = S_IF;
            end

            S_EX_ADDR: begin
                alu_b_sel = 1'b1;
                alu_op = ALU_ADD;
                use_mul = 1'b0;
                ld_aluout = 1'b1;
                if (is_load) state_n = S_MEM_RD1;
                else if (is_store) state_n = (is_store_rmw ? S_RMW_RD1 : S_MEM_WR);
                else state_n = S_IF;
            end

            S_MEM_RD1: begin
                mem_en_ctrl = 1'b1;
                mem_wen_ctrl = 1'b0;
                state_n = S_MEM_RD2;
            end

            S_MEM_RD2: begin
                ld_mdr = 1'b1;
                state_n = S_WB_LD;
            end

            S_WB_LD: begin
                reg_we = 1'b1;
                waddr_sel = 2'd1; // rt
                wdata_sel = 2'd1; // LoadData
                ld_pc = 1'b1;
                pc_sel = 2'd0;
                state_n = S_IF;
            end

            S_MEM_WR: begin
                mem_en_ctrl = 1'b1;
                mem_wen_ctrl = 1'b1; // write
                ld_pc = 1'b1;
                pc_sel = 2'd0;
                state_n = S_IF;
            end

            S_RMW_RD1: begin
                mem_en_ctrl = 1'b1;
                mem_wen_ctrl = 1'b0;
                state_n = S_RMW_RD2;
            end

            S_RMW_RD2: begin
                ld_mdr = 1'b1;
                state_n = S_RMW_WR;
            end

            S_RMW_WR: begin
                mem_en_ctrl = 1'b1;
                mem_wen_ctrl = 1'b1;
                ld_pc = 1'b1;
                pc_sel = 2'd0;
                state_n = S_IF;
            end

            S_MUL_START: begin
                use_mul = 1'b1;
                mul_valid_in = 1'b1;
                lo_hi = is_mul_lo ? 1'b1 : 1'b0;
                state_n = S_MUL_WAIT1;
            end

            S_MUL_WAIT1: begin
                use_mul = 1'b1;
                lo_hi = is_mul_lo ? 1'b1 : 1'b0;
                state_n = S_MUL_CAP;
            end

            S_MUL_CAP: begin
                use_mul = 1'b1;
                lo_hi = is_mul_lo ? 1'b1 : 1'b0;
                ld_aluout = 1'b1;
                state_n = S_WB_R;
            end

            S_WB_R: begin
                reg_we = 1'b1;
                wdata_sel = 2'd0;
                if (is_alu_imm) waddr_sel = 2'd1;
                else waddr_sel = 2'd0;
                ld_pc = 1'b1;
                pc_sel = 2'd0;
                state_n = S_IF;
            end
            default: state_n = S_IF;
        endcase
    end

endmodule
