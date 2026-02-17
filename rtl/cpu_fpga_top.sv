module cpu_fpga_top (
    input logic clk,
    input logic btnC,
    //input logic btnR, //mode for pipelining (not implemented yet)
    input logic [15:0] sw,
    input logic btnU,

    output logic [6:0] seg,
    output logic [3:0] an
);
    
    logic rst_n;
    logic mode = 0;
    
    logic reg_sel_btn;
    logic reg_sel_pulse;
    logic reg_sel_dbg = 0;
    
    logic [3:0] REG_addr_dbg;
    logic [15:0] REG_dbg;
        
    logic [31:0] PC_dbg;
    logic [31:0] IR_dbg;
    logic [31:0] ALUOut_dbg;
    logic [31:0] status_reg;
    
    assign rst_n = ~btnC;
    
    sw_encoder SE (
        .clk (clk),
        .sw (sw),
        .addr (REG_addr_dbg)
    );
    
    noise_rmv NR (
        .clk (clk),
        .rst_n (rst_n),
        .noisy_button (btnU),
        .clean_button (reg_sel_btn)
     );
    
     edge_detect ED (
        .clk (clk),
        .rst_n (rst_n),
        .clean_button (reg_sel_btn),
        .button_control (reg_sel_pulse)
     );
     
     always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) reg_sel_dbg <= 0;
        else if (reg_sel_pulse) reg_sel_dbg <= ~reg_sel_dbg;
     end
       
     sev_seg_ctrl SSC (
        .clk (clk),
        .rst_n (rst_n),
        .REG_dbg (REG_dbg),
        .seg_active (an),
        .seg_lit (seg)
     );  
    
    logic dmem_count;

    always_ff @(posedge clk) begin
        
    
    end
   
    // IMEM wires
    logic [12:0] imem_addr;
    logic [31:0] imem_rdata;

    // DMEM wires
    logic [12:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic dmem_wen;
    logic dmem_en;
    logic [31:0] dmem_rdata;

    // Flags / mul handshake
    logic zero, over, carry, neg;
    logic mul_valid_out;

    // Decoded field
    logic [4:0] rs_addr, rt_addr, rd_addr;
    logic [15:0] imm_val;
    logic upbound;

    // Control Unit to Data Path control signals
    logic clr_pc, ld_pc;
    logic [1:0] pc_sel;
    logic clr_ir, ld_ir;

    logic ld_a, ld_b, ld_aluout, ld_mdr;

    logic alu_b_sel;
    logic [3:0] alu_op;
    logic use_slt;
    logic [4:0] shamt;

    logic mul_valid_in;
    logic lo_hi;
    logic use_mul;

    logic br_sel;

    logic mem_en_ctrl;
    logic mem_wen_ctrl;
    logic [1:0]  mem_size;
    logic mem_unsigned;

    logic reg_we;
    logic [1:0] waddr_sel;
    logic [1:0] wdata_sel;

    logic [3:0] clr_flag;
    logic flag_en;

    // Instruction memory
    instr_mem IMEM (
        .addr (imem_addr),
        .instr (imem_rdata)
    );

    // Data memory
    data_mem DMEM (
        .clk (clk),
        .addr (dmem_addr),
        .data_in (dmem_wdata),
        .wen (dmem_wen),
        .en (dmem_en),
        .data_out (dmem_rdata)
    );

    // Datapath
    datapath_multi DP (
        .clk (clk),
        .rst_n (rst_n),
        .mode (mode),

        .imem_addr (imem_addr),
        .imem_rdata (imem_rdata),

        .dmem_addr (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_wen (dmem_wen),
        .dmem_en (dmem_en),
        .dmem_rdata (dmem_rdata),

        .rs_addr (rs_addr),
        .rt_addr (rt_addr),
        .rd_addr (rd_addr),
        .imm_val (imm_val),
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
        .shamt (shamt),

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
         
        .up_reg_sel(reg_sel_dbg),
        .dbg_reg_addr(REG_addr_dbg),
        .dbg_reg_data(REG_dbg),
        .IR_dbg (IR_dbg),
        .PC_dbg (PC_dbg),
        .ALUOut_dbg (ALUOut_dbg),
        .status_reg (status_reg),

        .zero (zero),
        .neg (neg),
        .cout (carry),
        .over (over)
    );

    // Control Unit
    control_unit_multi CU (
        .clk (clk),
        .rst_n (rst_n),
        .mode (mode),

        .IR (IR_dbg),
        .zero (zero),
        .over (over),
        .carry (carry),
        .neg (neg),
        .mul_valid_out (mul_valid_out),

        .rs_addr (rs_addr),
        .rt_addr (rt_addr),
        .rd_addr (rd_addr),
        .imm_val (imm_val),
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
        .alu_op (alu_op),
        .use_slt (use_slt),
        .shamt (shamt),

        .mul_valid_in (mul_valid_in),
        .lo_hi (lo_hi),
        .use_mul (use_mul),

        .br_sel (br_sel),

        .mem_en_ctrl (mem_en_ctrl),
        .mem_wen_ctrl (mem_wen_ctrl),
        .mem_size (mem_size),
        .mem_unsigned (mem_unsigned),

        .reg_we (reg_we),
        .waddr_sel (waddr_sel),
        .wdata_sel (wdata_sel),

        .clr_flag (clr_flag),
        .flag_en (flag_en)
    );

endmodule
