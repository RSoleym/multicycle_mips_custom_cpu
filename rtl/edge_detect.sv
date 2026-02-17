module edge_detect(
    input logic clk,
    input logic rst_n,
    input logic clean_button,
    output logic button_control
    );
    
    logic prev_button;
    
    always_ff @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            button_control <= 0;
            prev_button <= 0;
        end else begin
            if (prev_button != clean_button) begin
                prev_button <= clean_button;
                if (clean_button == 1)
                    button_control <= 1;
                else
                    button_control <= 0;                    
            end else 
                button_control <= 0;           
        end
        
    end
    
endmodule
