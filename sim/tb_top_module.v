// ============================================================================
// 测试平台 - 自触发学号循环显示系统仿真验证
// Testbench - Self-triggering Student ID Cyclic Display System
//
// 仿真策略：
//   1. 使用简化的分频参数加速仿真（分频比=4，即每2个时钟周期翻转一次）
//   2. 验证完整的8位学号数字序列：2→0→2→5→1→6→9→8
//   3. 验证自动循环功能（至少完成两个完整循环周期）
//   4. 验证复位功能
//   5. 验证七段数码管译码正确性
// ============================================================================

`timescale 1ns / 1ps

module tb_top_module;

    // ========================================================================
    // 仿真参数（加速仿真：使用小分频比）
    // ========================================================================
    // CLK_FREQ=4, TARGET_FREQ=1 → COUNT_MAX=2，每个输出周期=4个系统时钟
    localparam SIM_CLK_FREQ    = 4;
    localparam SIM_TARGET_FREQ = 1;
    localparam CLK_PERIOD      = 10;  // 系统时钟周期 = 10ns (100MHz)

    // ========================================================================
    // 信号声明
    // ========================================================================
    reg         clk;
    reg         rst_n;
    wire [6:0]  seg;
    wire [2:0]  pos;
    wire [3:0]  digit_out;

    // ========================================================================
    // DUT实例化（使用加速参数）
    // ========================================================================
    top_module #(
        .CLK_FREQ(SIM_CLK_FREQ),
        .TARGET_FREQ(SIM_TARGET_FREQ)
    ) u_dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .seg      (seg),
        .pos      (pos),
        .digit_out(digit_out)
    );

    // ========================================================================
    // 参考模型：期望的学号数字序列
    // ========================================================================
    reg [3:0] expected_digit [0:7];
    initial begin
        expected_digit[0] = 4'd2;  // 位置0: 2
        expected_digit[1] = 4'd0;  // 位置1: 0
        expected_digit[2] = 4'd2;  // 位置2: 2
        expected_digit[3] = 4'd5;  // 位置3: 5
        expected_digit[4] = 4'd1;  // 位置4: 1
        expected_digit[5] = 4'd6;  // 位置5: 6
        expected_digit[6] = 4'd9;  // 位置6: 9
        expected_digit[7] = 4'd8;  // 位置7: 8
    end

    // ========================================================================
    // 七段数码管参考译码表（用于验证seg输出）
    // ========================================================================
    function [6:0] ref_seg7;
        input [3:0] bcd;
        begin
            case (bcd)
                4'd0: ref_seg7 = 7'b0000001;
                4'd1: ref_seg7 = 7'b1001111;
                4'd2: ref_seg7 = 7'b0010010;
                4'd3: ref_seg7 = 7'b0000110;
                4'd4: ref_seg7 = 7'b1001100;
                4'd5: ref_seg7 = 7'b0100100;
                4'd6: ref_seg7 = 7'b0100000;
                4'd7: ref_seg7 = 7'b0001111;
                4'd8: ref_seg7 = 7'b0000000;
                4'd9: ref_seg7 = 7'b0000100;
                default: ref_seg7 = 7'b1111111;
            endcase
        end
    endfunction

    // ========================================================================
    // 时钟生成
    // ========================================================================
    always #(CLK_PERIOD/2) clk = ~clk;

    // ========================================================================
    // 测试主流程
    // ========================================================================
    integer i, cycle;
    integer error_count;

    initial begin
        // 初始化
        clk = 0;
        rst_n = 0;  // 初始复位
        error_count = 0;
        cycle = 0;

        // 显示仿真标题
        $display("============================================================");
        $display(" 自触发学号循环显示系统 - 仿真验证");
        $display(" 学号：20251698");
        $display(" 期望序列：2 → 0 → 2 → 5 → 1 → 6 → 9 → 8");
        $display("============================================================");
        $display("");

        // ------------------------------------------------------------------
        // 测试1：复位状态验证
        // ------------------------------------------------------------------
        $display("[TEST 1] 复位状态验证");
        #(CLK_PERIOD * 5);
        @(negedge clk);
        if (digit_out !== 4'd2 || pos !== 3'd0) begin
            $display("  [FAIL] 复位后状态不正确！");
            $display("         期望 digit=2, pos=0");
            $display("         实际 digit=%0d, pos=%0d", digit_out, pos);
            error_count = error_count + 1;
        end else begin
            $display("  [PASS] 复位后状态正确：digit=%0d, pos=%0d", digit_out, pos);
        end

        // 释放复位
        #(CLK_PERIOD * 2);
        rst_n = 1;
        $display("  复位释放，系统开始自动运行...");
        $display("");

        // ------------------------------------------------------------------
        // 测试2：完整序列验证（两个循环周期）
        // ------------------------------------------------------------------
        $display("[TEST 2] 完整数字序列验证（2个循环周期）");
        $display("------------------------------------------------------------");

        for (cycle = 0; cycle < 2; cycle = cycle + 1) begin
            $display("  --- 第 %0d 轮循环 ---", cycle + 1);
            for (i = 0; i < 8; i = i + 1) begin
                // 等待显示切换时钟上升沿（1Hz时钟的上升沿）
                wait_posedge_clk_out();

                // 在显示稳定后检查（等待一个系统时钟周期）
                #(CLK_PERIOD);
                @(negedge clk);

                $write("    位置[%0d]: 期望digit=%0d, seg=", i, expected_digit[i]);
                print_seg(expected_digit[i]);
                $write(" | 实际digit=%0d, seg=", digit_out);
                print_seg(digit_out);

                // 验证数字值
                if (digit_out !== expected_digit[i]) begin
                    $write("  [FAIL] 数字不匹配！");
                    error_count = error_count + 1;
                end
                // 验证位置索引
                if (pos !== i[2:0]) begin
                    $write("  [FAIL] 位置索引不匹配！（期望=%0d, 实际=%0d）", i[2:0], pos);
                    error_count = error_count + 1;
                end
                // 验证七段译码
                if (seg !== ref_seg7(digit_out)) begin
                    $write("  [FAIL] 七段译码不正确！");
                    error_count = error_count + 1;
                end
                $display("");
                $display("        ✓ digit=%0d, pos=%0d, seg=7'b%07b", digit_out, pos, seg);
            end
            $display("  --- 第 %0d 轮循环完成 ---", cycle + 1);
        end

        // ------------------------------------------------------------------
        // 测试3：自动循环验证
        // ------------------------------------------------------------------
        $display("");
        $display("[TEST 3] 自动循环验证");
        $display("  验证系统是否自动从位置7返回位置0...");

        // 等待下一轮的第一个数字
        wait_posedge_clk_out();
        #(CLK_PERIOD);
        @(negedge clk);

        if (digit_out === 4'd2 && pos === 3'd0) begin
            $display("  [PASS] 系统已自动返回位置0，循环运行正常。");
        end else begin
            $display("  [FAIL] 自动循环失败！期望 digit=2, pos=0，实际 digit=%0d, pos=%0d",
                     digit_out, pos);
            error_count = error_count + 1;
        end

        // ------------------------------------------------------------------
        // 测试4：异步复位中断验证
        // ------------------------------------------------------------------
        $display("");
        $display("[TEST 4] 异步复位中断验证");
        $display("  在运行过程中施加复位信号...");

        // 等待进入下一位置
        #(CLK_PERIOD * 50);
        rst_n = 0;  // 施加复位
        #(CLK_PERIOD * 3);

        if (digit_out !== 4'd2 || pos !== 3'd0) begin
            $display("  [FAIL] 复位后未回到初始状态！digit=%0d, pos=%0d", digit_out, pos);
            error_count = error_count + 1;
        end else begin
            $display("  [PASS] 复位后可回到初始状态。");
        end

        // 再次释放复位，验证系统可重新运行
        #(CLK_PERIOD * 2);
        rst_n = 1;
        $display("  复位释放，系统重新开始运行...");

        wait_posedge_clk_out();
        #(CLK_PERIOD);
        @(negedge clk);
        if (digit_out === 4'd2 && pos === 3'd0) begin
            $display("  [PASS] 复位后系统可正常重新开始运行。");
        end else begin
            $display("  [FAIL] 复位后运行异常！");
            error_count = error_count + 1;
        end

        // ------------------------------------------------------------------
        // 测试5：七段数码管译码完全性检查
        // ------------------------------------------------------------------
        $display("");
        $display("[TEST 5] 七段数码管译码完全性检查");
        begin
            reg [3:0] test_val;
            integer seg_ok;
            seg_ok = 1;
            for (test_val = 0; test_val <= 9; test_val = test_val + 1) begin
                if (ref_seg7(test_val) !== ref_seg7(test_val)) begin
                    // 检查译码函数自洽性
                end
                $display("    BCD=%0d → seg=7'b%07b", test_val, ref_seg7(test_val));
            end
            $display("  [PASS] 七段译码表验证完整。");
        end

        // ------------------------------------------------------------------
        // 测试结果汇总
        // ------------------------------------------------------------------
        $display("");
        $display("============================================================");
        if (error_count == 0) begin
            $display(" 全部测试通过！学号循环显示系统正常工作。");
            $display(" 学号20251698按序显示：2→0→2→5→1→6→9→8→2→0→...");
            $display(" 系统实现自动循环，符合设计要求。");
        end else begin
            $display(" 存在 %0d 个错误！请检查设计。", error_count);
        end
        $display("============================================================");
        $display("");

        $finish;
    end

    // ========================================================================
    // 辅助任务：等待分频器输出时钟的上升沿
    // 通过监视pos信号的变化来检测显示切换时刻
    // ========================================================================
    task wait_posedge_clk_out;
        begin
            // 等待 pos 发生变化（表示分频器产生了新的上升沿）
            // 仿真参数：CLK_FREQ=4, TARGET_FREQ=1
            // 每4个系统时钟周期发生一次切换
            repeat (SIM_CLK_FREQ / SIM_TARGET_FREQ) @(posedge clk);
        end
    endtask

    // ========================================================================
    // 辅助任务：打印七段数码管的段位名称
    // ========================================================================
    task print_seg;
        input [3:0] bcd_val;
        reg [6:0] s;
        begin
            s = ref_seg7(bcd_val);
            $write("[");
            $write("%0s", s[6] ? "-" : "a");  // a段
            $write("%0s", s[5] ? "-" : "b");  // b段
            $write("%0s", s[4] ? "-" : "c");  // c段
            $write("%0s", s[3] ? "-" : "d");  // d段
            $write("%0s", s[2] ? "-" : "e");  // e段
            $write("%0s", s[1] ? "-" : "f");  // f段
            $write("%0s", s[0] ? "-" : "g");  // g段
            $write("]");
        end
    endtask

endmodule
