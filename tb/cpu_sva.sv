module cpu_sva(
    input logic clk,
    input logic rst_n,
    input logic [31:0] pc,
    input logic [31:0] ir,
    input logic clr_pc,
    input logic ld_pc,
    input logic clr_ir,
    input logic ld_ir,
    input logic dmem_en,
    input logic dmem_wen,
    input logic [12:0] dmem_addr,
    input logic reg_we,
    input logic [1:0] waddr_sel,
    input logic [4:0] rd_addr,
    input logic [4:0] rt_addr
);
    logic [31:0] pc_prev, ir_prev;
    logic ld_pc_prev, clr_pc_prev, ld_ir_prev, clr_ir_prev;
    logic [4:0] waddr_eff;
    always_comb begin
        unique case(waddr_sel)
            2'd0: waddr_eff = rd_addr;
            2'd1: waddr_eff = rt_addr;
            2'd2: waddr_eff = 5'd15;
            default: waddr_eff = rd_addr;
        endcase
    end
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            pc_prev <= pc;
            ir_prev <= ir;
            ld_pc_prev <= 1'b0;
            clr_pc_prev <= 1'b0;
            ld_ir_prev <= 1'b0;
            clr_ir_prev <= 1'b0;
        end else begin
            pc_prev <= pc;
            ir_prev <= ir;
            ld_pc_prev <= ld_pc;
            clr_pc_prev <= clr_pc;
            ld_ir_prev <= ld_ir;
            clr_ir_prev <= clr_ir;
        end
    end

    a_pc_word_aligned: assert property (@(posedge clk) disable iff (!rst_n) pc[1:0]==2'b00) 
    else $error("SVA: PC not word-aligned pc=%h",pc);

    a_pc_change_authorized: assert property (@(posedge clk) disable iff (!rst_n) (pc!=pc_prev) |-> (ld_pc_prev || clr_pc_prev)) 
    else $error("SVA: PC changed without prior ld_pc/clr_pc ld_prev=%b clr_prev=%b pc=%h pc_prev=%h", ld_pc_prev, clr_pc_prev, pc, pc_prev);

    a_ir_change_authorized: assert property (@(posedge clk) disable iff (!rst_n)(ir!=ir_prev) |-> (ld_ir_prev || clr_ir_prev)) 
    else $error("SVA: IR changed without prior ld_ir/clr_ir ld_prev=%b clr_prev=%b ir=%h ir_prev=%h", ld_ir_prev, clr_ir_prev, ir,ir_prev);

    a_store_implies_en: assert property (@(posedge clk) disable iff (!rst_n) dmem_wen |-> dmem_en) 
    else $error("SVA: dmem_wen without dmem_en");

    a_no_write_r0: assert property (@(posedge clk) disable iff (!rst_n) !(reg_we && (waddr_eff == 5'd0))) 
    else $error("SVA: Write attempted to R0 waddr_sel=%0d rd=%0d rt=%0d", waddr_sel, rd_addr, rt_addr);

    c_seen_writeback: cover property (@(posedge clk) disable iff (!rst_n) reg_we);
endmodule