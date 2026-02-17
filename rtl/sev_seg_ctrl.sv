module sev_seg_ctrl
# (parameter TICKS_PER_MILLI = 100_000)
(
    input logic clk,
    input logic rst_n,
    input logic [15:0] REG_dbg,
    output logic [3:0] seg_active,
    output logic [6:0] seg_lit
);
    
    logic [3:0] current_num;
    logic [$clog2(TICKS_PER_MILLI) - 1:0] milli_counter;
    
    localparam logic [3:0] an_values [0:3] = '{
        4'b1110, //Most Right
        4'b1101, //Middle Right
        4'b1011, //Middle Left
        4'b0111  //Most Left
    }; 
   
    typedef enum logic [1:0] {
        BIT_ONE,
        BIT_TWO,
        BIT_THREE,
        BIT_FOUR
    } position; 
    
    position seg_position;
    
    sev_seg_dec SEGMENT_DECODER (
        .dec_value(current_num),
        .seg_value(seg_lit)
    );
    
    always_comb begin
        seg_active = an_values[0];
        current_num = REG_dbg[3:0];
        
        case (seg_position)
           BIT_ONE: begin current_num = REG_dbg[3:0]; seg_active = an_values[0]; end
           BIT_TWO: begin current_num = REG_dbg[7:4]; seg_active = an_values[1]; end 
           BIT_THREE: begin current_num = REG_dbg[11:8]; seg_active = an_values[2]; end
           BIT_FOUR: begin current_num = REG_dbg[15:12]; seg_active = an_values[3]; end
           default: begin current_num = REG_dbg[3:0]; seg_active = an_values[0]; end
        endcase   
    end
    
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seg_position <= BIT_ONE;
            milli_counter <= 0;
        end else begin
            if (milli_counter < TICKS_PER_MILLI - 1) milli_counter <= milli_counter + 1;
            else begin
                milli_counter <= 0;
                case (seg_position)
                    BIT_ONE: seg_position <= BIT_TWO; 
                    BIT_TWO: seg_position <= BIT_THREE; 
                    BIT_THREE: seg_position <= BIT_FOUR;
                    BIT_FOUR: seg_position <= BIT_ONE; 
                    default: seg_position <= BIT_ONE;
                endcase
            end
        end
    end     
endmodule
