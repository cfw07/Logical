// ============================================================================
// 数字控制器模块 - 3位计数器，循环产生0~7的数码管位选地址
// Digit Controller - 3-bit counter cycling 0~7 for digit position selection
//
// 功能：在输入时钟触发下，从0到7循环计数，对应学号的8位数字。
//       当计数到7后再回到0，实现自动循环。
// ============================================================================

module digit_controller (
    input  wire       clk,       // 显示切换时钟（来自分频器）
    input  wire       rst_n,     // 异步复位（低有效）
    output reg  [2:0] digit_sel  // 当前显示数字的位置索引（0~7）
);

    // 3位计数器，循环0~7
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            digit_sel <= 3'd0;
        end else begin
            if (digit_sel == 3'd7) begin
                digit_sel <= 3'd0;  // 循环回到起始位置
            end else begin
                digit_sel <= digit_sel + 1;
            end
        end
    end

endmodule
