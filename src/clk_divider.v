// ============================================================================
// 时钟分频模块 - 将高频系统时钟分频为低频显示刷新时钟
// Clock Divider - Divides system clock to generate display refresh clock
//
// 设计依据：
//   - 系统时钟频率：50MHz（典型FPGA开发板时钟）
//   - 显示切换间隔：1秒（适合人眼观察，方便仿真验证）
//   - 分频比：50,000,000 : 1
//
// 时间间隔选择理由：
//   1秒是人眼可清晰分辨的时间单位，既不会过快导致看不清，
//   也不会过慢导致等待时间过长，便于观察和验证系统的循环显示功能。
// ============================================================================

module clk_divider #(
    parameter CLK_FREQ     = 50_000_000,  // 系统时钟频率 (Hz)
    parameter TARGET_FREQ  = 1             // 目标输出频率 (Hz)
) (
    input  wire clk_in,     // 输入时钟
    input  wire rst_n,      // 异步复位（低有效）
    output reg  clk_out     // 分频后输出时钟
);

    // 计算分频计数上限（实现50%占空比，在计数到一半时翻转）
    localparam COUNT_MAX = CLK_FREQ / (2 * TARGET_FREQ);

    // 计数器寄存器
    reg [$clog2(COUNT_MAX)-1:0] counter;

    // 计数器位宽自动计算
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            clk_out <= 1'b0;
        end else begin
            if (counter >= COUNT_MAX - 1) begin
                counter <= 0;
                clk_out <= ~clk_out;  // 翻转输出，产生50%占空比
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
