module sw_encoder(
    input logic clk,
    input logic [15:0] sw,
    output logic [3:0] addr
);

    integer i;
    logic [15:0] prev_sw;
    
    always_ff @(posedge clk) begin
        if (sw != prev_sw) begin
            addr <= 0;
            for (i = 0; i < 16; i = i + 1) begin 
                if (sw[i]) addr <= i[3:0]; 
            end
            prev_sw <= sw;
        end //else do nothing
    end 

endmodule
