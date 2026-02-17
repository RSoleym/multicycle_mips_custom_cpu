module multiplier_blk(
    input logic clk,
    input logic rst_n,
    input logic lo_hi,
    input logic valid_in,
    input logic signed [31:0] a,
    input logic signed [31:0] b,
    output logic signed [31:0] result,
    output logic valid_out
);

    logic signed [63:0] prod;
    logic lo_hi_q;
    
    typedef enum logic [1:0] {
        BUSY,
        DONE,
        IDLE
    }status_t;
    
    status_t status;
    
    always_ff @(posedge clk or negedge rst_n) begin
        valid_out <= 0;
        if (!rst_n) begin
            status <= IDLE;
            prod <= 0;
            result <= 0;
            valid_out <= 0;
            lo_hi_q <= 0;
        end else begin 
            if (valid_in && status != BUSY) begin
                prod <= a * b;
                lo_hi_q <= lo_hi;
                status <= BUSY;
            end else if (status == BUSY) begin
                if (lo_hi_q) result <= prod[31:0];
                else result <= prod[63:32];
                valid_out <= 1;
                status <= DONE;
            end else if (status == DONE) begin
                valid_out <= 0;
                status <= IDLE;
            end //else do IDLE
        end
                    
    end
    
endmodule
