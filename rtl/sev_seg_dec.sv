module sev_seg_dec(
    input logic [3:0] dec_value,
    output logic [6:0] seg_value
    );
    
    localparam logic [6:0] SEG_NUM [0:15] = '{
        7'b1000000, // 0
        7'b1111001, // 1
        7'b0100100, // 2
        7'b0110000, // 3
        7'b0011001, // 4
        7'b0010010, // 5
        7'b0000010, // 6
        7'b1111000, // 7
        7'b0000000, // 8
        7'b0010000, // 9
        7'b0001000, // A
        7'b0000011, // b
        7'b1000110, // C
        7'b0100001, // d
        7'b0000110, // E
        7'b0001110  // F
    };
  
     
     assign seg_value = SEG_NUM[dec_value];
    
endmodule
