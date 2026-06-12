// ============================================================================
// 七段数码管译码器 - 将4位BCD码转换为七段数码管驱动信号
// 7-Segment Decoder - Converts 4-bit BCD to 7-segment display signals
//
// 七段数码管段位定义（低有效）：
//       a
//     ┌───┐
//   f │ g │ b
//     ├───┤
//   e │   │ c
//     └───┘
//       d
//
// 输出位映射：{a, b, c, d, e, f, g}
// 采用共阳极数码管驱动方式（低电平点亮）
// ============================================================================

module seg7_decoder (
    input  wire  [3:0] bcd_in,   // 4位BCD码输入（0~9）
    output reg   [6:0] seg_out   // 7段数码管输出（低有效），{a,b,c,d,e,f,g}
);

    always @(*) begin
        case (bcd_in)
            4'd0: seg_out = 7'b0000001;  // 0: 除g外全亮
            4'd1: seg_out = 7'b1001111;  // 1: 仅b, c亮
            4'd2: seg_out = 7'b0010010;  // 2: a,b,d,e,g亮
            4'd3: seg_out = 7'b0000110;  // 3: a,b,c,d,g亮
            4'd4: seg_out = 7'b1001100;  // 4: b,c,f,g亮
            4'd5: seg_out = 7'b0100100;  // 5: a,c,d,f,g亮
            4'd6: seg_out = 7'b0100000;  // 6: a,c,d,e,f,g亮
            4'd7: seg_out = 7'b0001111;  // 7: a,b,c亮
            4'd8: seg_out = 7'b0000000;  // 8: 全亮
            4'd9: seg_out = 7'b0000100;  // 9: a,b,c,d,f,g亮
            default: seg_out = 7'b1111111; // 全灭
        endcase
    end

endmodule
