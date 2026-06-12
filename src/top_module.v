// ============================================================================
// 顶层模块 - 自触发学号循环显示系统
// Top Module - Self-triggering Student ID Cyclic Display System
//
// 系统功能：
//   无需人工按键触发，系统启动后自动运行，按照设定的时间间隔
//   循环显示学号20251698的各位数字。显示顺序与学号数字顺序一致，
//   全部显示完成后自动返回起始位置循环运行。
//
// 模块架构：
//   clk ──→ clk_divider ──→ digit_controller ──→ student_id_rom ──→ seg7_decoder ──→ display
//
// 设计参数：
//   - 系统时钟：50MHz
//   - 显示刷新间隔：1秒
//   - 可显示数字：8位学号
//
// 端口说明：
//   输入：clk (系统时钟), rst_n (复位)
//   输出：seg (七段数码管), pos (当前显示位置，用于调试)
// ============================================================================

module top_module #(
    parameter CLK_FREQ    = 50_000_000,  // 系统时钟频率 (Hz)
    parameter TARGET_FREQ = 1             // 显示切换频率 (Hz)
) (
    input  wire       clk,       // 系统时钟输入（50MHz）
    input  wire       rst_n,     // 异步复位（低有效）
    output wire [6:0] seg,       // 七段数码管段选信号 {a,b,c,d,e,f,g}
    output wire [2:0] pos,       // 当前显示的数字位置（0~7），供调试用
    output wire [3:0] digit_out  // 当前显示的BCD数字，供调试用
);

    // ========================================================================
    // 内部连线声明
    // ========================================================================
    wire        clk_1hz;     // 1Hz显示切换时钟
    wire [2:0]  digit_sel;   // 数字位置选择信号

    // ========================================================================
    // 模块实例化
    // ========================================================================

    // 时钟分频器：50MHz → 1Hz
    clk_divider #(
        .CLK_FREQ(CLK_FREQ),
        .TARGET_FREQ(TARGET_FREQ)
    ) u_clk_divider (
        .clk_in (clk),
        .rst_n  (rst_n),
        .clk_out(clk_1hz)
    );

    // 数字控制器：产生循环的位选信号
    digit_controller u_digit_ctrl (
        .clk      (clk_1hz),
        .rst_n    (rst_n),
        .digit_sel(digit_sel)
    );

    // 学号ROM：将位选信号映射为对应的学号数字
    student_id_rom u_id_rom (
        .addr (digit_sel),
        .digit(digit_out)
    );

    // 七段数码管译码器：将BCD码转换为段选信号
    seg7_decoder u_seg7 (
        .bcd_in (digit_out),
        .seg_out(seg)
    );

    // 位置信号输出
    assign pos = digit_sel;

endmodule
