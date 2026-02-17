`timescale 1ns/1ps
module cpu_tb;

    logic clk;
    logic rst_n;
    logic mode;

    logic [3:0] REG_addr_dbg;
    logic reg_sel_dbg;
    logic [15:0] REG_dbg;

    logic [31:0] PC_dbg;
    logic [31:0] IR_dbg;
    logic [31:0] ALUOut_dbg;
    logic [31:0] status_reg;

    cpu_top DUT(
        .clk (clk),
        .rst_n (rst_n),
        .mode (mode),
        .REG_addr_dbg (REG_addr_dbg),
        .reg_sel_dbg (reg_sel_dbg),
        .PC_dbg (PC_dbg),
        .IR_dbg (IR_dbg),
        .ALUOut_dbg (ALUOut_dbg),
        .status_reg (status_reg),
        .REG_dbg (REG_dbg)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    int pc_same_updates;
    logic [31:0] last_pc_update;

    initial begin
        mode = 0;
        rst_n = 0;

        REG_addr_dbg = 0;
        reg_sel_dbg = 0;

        pc_same_updates = 0;
        last_pc_update = 32'hFFFF_FFFF;

        #100;
        rst_n = 1;

        forever begin
            @(posedge clk);
            #1;

            if (DUT.ld_pc) begin
                $display("PC=%08h IR=%08h ALUOut=%08h STATUS=%08h", PC_dbg, IR_dbg, ALUOut_dbg, status_reg);

                if (PC_dbg === last_pc_update) pc_same_updates++;
                else pc_same_updates = 0;

                last_pc_update = PC_dbg;

                if (pc_same_updates >= 2) begin
                    $display("[TB] DONE detected: PC repeated on ld_pc updates (PC=%08h)", PC_dbg);
                    break;
                end
            end
        end

        $display("----- REGISTERS -----");
        for (int i = 0; i < 16; i++) begin
            logic [15:0] lo16, hi16;

            REG_addr_dbg = i[3:0];

            reg_sel_dbg = 0; @(posedge clk); #1; lo16 = REG_dbg;
            reg_sel_dbg = 1; @(posedge clk); #1; hi16 = REG_dbg;

            $display("R%0d = 0x%04h_%04h", i, hi16, lo16);
        end

        $finish;
    end

endmodule
