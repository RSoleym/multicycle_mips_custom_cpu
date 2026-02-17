module noise_rmv
    # (parameter PRESS_DURATION = 10**6) //10 milliseconds for button to be registered 
    (
    input logic clk,
    input logic rst_n,
    input logic noisy_button,
    output logic clean_button
    );
    
    logic [$clog2(PRESS_DURATION) - 1:0] press_clk_count;
    logic prev_button;
    
    always_ff @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            press_clk_count <= 0;
            prev_button <= 0;
            clean_button <= 0;
        end else begin
            if (press_clk_count < PRESS_DURATION - 1) begin
                if (prev_button != noisy_button) begin
                    prev_button <= noisy_button;
                    press_clk_count <= 0;
                end else
                    press_clk_count <= press_clk_count + 1;
            end else begin
                clean_button <= prev_button;
                press_clk_count <= 0;
            end
        end 
        
       
    end
endmodule
