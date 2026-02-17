module instr_mem(
    input logic [12:0] addr,
    output logic [31:0] instr
);
    
    logic [31:0] instr_addr [2047:0];
    initial begin
        $readmemh("hex_instr.hex", instr_addr); 
    end

    assign instr = instr_addr[(addr>>2)];

    
endmodule
