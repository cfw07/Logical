# 基于数字电路设计的自触发学号循环显示系统

## 设计报告

---

**学号：20251698**

**课题：基于数字电路设计的自触发学号循环显示系统**

---

## 一、课题分析与总体方案设计

### 1.1 课题分析

本课题要求设计一个自触发数字电路，实现以下功能：

- **自触发运行**：系统上电后无需人工按键触发，自动开始运行
- **循环显示**：按照固定时间间隔循环显示学号（20251698）中的各位数字
- **顺序一致**：显示顺序必须与学号数字顺序一致
- **自动循环**：全部数字显示完成后自动返回初始状态，循环往复

学号 **20251698** 共8位数字，分解如下：

| 位置 | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|------|---|---|---|---|---|---|---|---|
| 数字 | 2 | 0 | 2 | 5 | 1 | 6 | 9 | 8 |

### 1.2 总体方案设计

系统采用**自顶向下**的模块化设计方法，将系统分解为四个主要功能模块，通过顶层模块统一集成。

#### 系统架构框图

```
                    ┌──────────────────────────────────────────────────────────┐
                    │                      top_module                           │
                    │                                                          │
  clk (50MHz) ─────┤                                                          │
                    │   ┌──────────────┐      ┌─────────────────┐             │
  rst_n ───────────┤──▶│  clk_divider │      │                 │             │
                    │   │  (50M -> 1Hz)│─────▶│ digit_controller│             │
                    │   │              │      │  (mod-8 counter) │             │
                    │   └──────────────┘      └────────┬────────┘             │
                    │                                  │                       │
                    │                                  │ addr[2:0]             │
                    │                                  ▼                       │
                    │                         ┌─────────────────┐             │
                    │                         │ student_id_rom  │             │
                    │                         │ (8x4 lookup)    │             │
                    │                         └────────┬────────┘             │
                    │                                  │ digit[3:0]            │
                    │                                  ▼                       │
                    │                         ┌─────────────────┐             │
                    │                         │  seg7_decoder   │             │
                    │                         │  (BCD -> 7seg)  │             │
                    │                         └────────┬────────┘             │
                    │                                  │ seg[6:0]              │
                    │                                  ▼                       │
                    │                            七段数码管显示                │
                    └──────────────────────────────────────────────────────────┘
```

### 1.3 显示时间间隔设计依据

**本设计选择1秒作为显示切换间隔**，设计依据如下：

1. **人眼视觉特性**：1秒是人眼可清晰分辨的时间单位。人眼的视觉暂留时间约为0.1~0.2秒，1秒的间隔既不会因过快而导致视觉疲劳或无法辨认，也不会因过慢而影响观察效率
2. **标准时间基准**：1秒作为国际单位制基本单位，易于从标准时钟频率（如50MHz）精确分频得到
3. **仿真验证便利**：1秒间隔在仿真中容易验证（计数50,000,000个时钟周期），逻辑简单明确
4. **可调性**：设计采用参数化方式实现，可根据实际需要灵活调整显示间隔

系统时钟采用典型FPGA开发板时钟频率**50MHz**（周期20ns），需通过分频器将50MHz分频至1Hz。

**分频比计算**：50,000,000 / 1 = 50,000,000 : 1

为实现50%占空比输出，采用计数器翻转法：
- 计数上限 = 50,000,000 / (2 × 1) = 25,000,000
- 每计满25,000,000个时钟周期翻转输出一次

---

## 二、电路设计

### 2.1 模块划分

系统由以下四个子模块和一个顶层集成模块组成：

| 模块名称 | 文件名 | 功能描述 |
|----------|--------|----------|
| clk_divider | clk_divider.v | 将50MHz系统时钟分频为1Hz显示刷新时钟 |
| digit_controller | digit_controller.v | 3位计数器，循环产生0~7的位选地址 |
| student_id_rom | student_id_rom.v | 学号查找表，将位置映射为数字 |
| seg7_decoder | seg7_decoder.v | BCD码转七段数码管译码 |
| top_module | top_module.v | 顶层集成，连接所有子模块 |

### 2.2 时钟分频器 (clk_divider)

**功能**：将高频系统时钟分频为低频显示刷新时钟。

**电路结构**：
- 25位计数器（`$clog2(25,000,000)` = 25位）
- 比较器和输出翻转逻辑
- 异步复位控制

**工作原理**：
1. 每个系统时钟上升沿，计数器加1
2. 计数器达到25,000,000 - 1时归零，同时输出翻转
3. 输出频率 = 50MHz / (2 × 25,000,000) = 1Hz，占空比50%

### 2.3 数字位置控制器 (digit_controller)

**功能**：在分频时钟驱动下，产生0→1→2→3→4→5→6→7→0→...的循环计数序列。

**电路结构**：
- 3位二进制计数器
- 复位时归零

**状态转移**：
```
Reset → S0(000) → S1(001) → S2(010) → S3(011) → S4(100) → S5(101) → S6(110) → S7(111) → S0(000) → ...
```

### 2.4 学号查找表 (student_id_rom)

**功能**：将3位位置地址映射为对应学号数字的4位BCD码。

**真值表**：

| 输入 addr[2:0] | 输出 digit[3:0] | 对应学号位 |
|:---:|:---:|:---:|
| 000 | 0010 (2) | 第1位 |
| 001 | 0000 (0) | 第2位 |
| 010 | 0010 (2) | 第3位 |
| 011 | 0101 (5) | 第4位 |
| 100 | 0001 (1) | 第5位 |
| 101 | 0110 (6) | 第6位 |
| 110 | 1001 (9) | 第7位 |
| 111 | 1000 (8) | 第8位 |

**实现方式**：组合逻辑case语句，纯组合电路，无时序元件。

### 2.5 七段数码管译码器 (seg7_decoder)

**功能**：将4位BCD码转换为七段数码管段选信号。

**数码管段位定义（共阳极，低有效）**：
```
       a
     ┌───┐
   f │ g │ b
     ├───┤
   e │   │ c
     └───┘
       d
```

输出格式：`{a, b, c, d, e, f, g}`（低电平点亮）

**译码真值表**：

| BCD | a | b | c | d | e | f | g | 显示 |
|:---:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:---:|
| 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | "0" |
| 1 | 1 | 0 | 0 | 1 | 1 | 1 | 1 | "1" |
| 2 | 0 | 0 | 1 | 0 | 0 | 1 | 0 | "2" |
| 3 | 0 | 0 | 0 | 0 | 1 | 1 | 0 | "3" |
| 4 | 1 | 0 | 0 | 1 | 1 | 0 | 0 | "4" |
| 5 | 0 | 1 | 0 | 0 | 1 | 0 | 0 | "5" |
| 6 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | "6" |
| 7 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | "7" |
| 8 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | "8" |
| 9 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | "9" |

### 2.6 顶层模块 (top_module)

**功能**：将四个子模块互联，构成完整的自触发学号循环显示系统。

**信号连接**：
- 系统时钟 → clk_divider的clk_in
- clk_divider的clk_out → digit_controller的clk
- digit_controller的digit_sel → student_id_rom的addr
- student_id_rom的digit → seg7_decoder的bcd_in
- seg7_decoder的seg_out → 外部七段数码管

---

## 三、电路实现（Verilog实现）

### 3.1 时钟分频器 (clk_divider.v)

```verilog
module clk_divider #(
    parameter CLK_FREQ     = 50_000_000,  // 系统时钟频率 (Hz)
    parameter TARGET_FREQ  = 1             // 目标输出频率 (Hz)
) (
    input  wire clk_in,     // 输入时钟
    input  wire rst_n,      // 异步复位（低有效）
    output reg  clk_out     // 分频后输出时钟
);

    localparam COUNT_MAX = CLK_FREQ / (2 * TARGET_FREQ);
    reg [$clog2(COUNT_MAX)-1:0] counter;

    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            clk_out <= 1'b0;
        end else begin
            if (counter >= COUNT_MAX - 1) begin
                counter <= 0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
```

**关键设计特点**：
- 参数化设计，`CLK_FREQ`和`TARGET_FREQ`可配置
- `$clog2()`自动计算计数器位宽
- 50%占空比输出
- 异步复位

### 3.2 数字位置控制器 (digit_controller.v)

```verilog
module digit_controller (
    input  wire       clk,       // 显示切换时钟
    input  wire       rst_n,     // 异步复位（低有效）
    output reg  [2:0] digit_sel  // 当前数字位置（0~7）
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            digit_sel <= 3'd0;
        end else begin
            if (digit_sel == 3'd7)
                digit_sel <= 3'd0;
            else
                digit_sel <= digit_sel + 1;
        end
    end
endmodule
```

### 3.3 学号查找表 (student_id_rom.v)

```verilog
module student_id_rom (
    input  wire  [2:0] addr,   // 数字位置索引
    output reg   [3:0] digit   // BCD数字输出
);

    always @(*) begin
        case (addr)
            3'd0: digit = 4'd2;  // 位置0：数字 2
            3'd1: digit = 4'd0;  // 位置1：数字 0
            3'd2: digit = 4'd2;  // 位置2：数字 2
            3'd3: digit = 4'd5;  // 位置3：数字 5
            3'd4: digit = 4'd1;  // 位置4：数字 1
            3'd5: digit = 4'd6;  // 位置5：数字 6
            3'd6: digit = 4'd9;  // 位置6：数字 9
            3'd7: digit = 4'd8;  // 位置7：数字 8
            default: digit = 4'd0;
        endcase
    end
endmodule
```

### 3.4 七段数码管译码器 (seg7_decoder.v)

```verilog
module seg7_decoder (
    input  wire  [3:0] bcd_in,
    output reg   [6:0] seg_out   // {a,b,c,d,e,f,g}，低有效
);

    always @(*) begin
        case (bcd_in)
            4'd0: seg_out = 7'b0000001;
            4'd1: seg_out = 7'b1001111;
            4'd2: seg_out = 7'b0010010;
            4'd3: seg_out = 7'b0000110;
            4'd4: seg_out = 7'b1001100;
            4'd5: seg_out = 7'b0100100;
            4'd6: seg_out = 7'b0100000;
            4'd7: seg_out = 7'b0001111;
            4'd8: seg_out = 7'b0000000;
            4'd9: seg_out = 7'b0000100;
            default: seg_out = 7'b1111111;
        endcase
    end
endmodule
```

### 3.5 顶层模块 (top_module.v)

```verilog
module top_module #(
    parameter CLK_FREQ    = 50_000_000,
    parameter TARGET_FREQ = 1
) (
    input  wire       clk,
    input  wire       rst_n,
    output wire [6:0] seg,
    output wire [2:0] pos,
    output wire [3:0] digit_out
);

    wire        clk_1hz;
    wire [2:0]  digit_sel;

    clk_divider #(.CLK_FREQ(CLK_FREQ), .TARGET_FREQ(TARGET_FREQ))
        u_clk_divider (.clk_in(clk), .rst_n(rst_n), .clk_out(clk_1hz));

    digit_controller u_digit_ctrl
        (.clk(clk_1hz), .rst_n(rst_n), .digit_sel(digit_sel));

    student_id_rom u_id_rom (.addr(digit_sel), .digit(digit_out));

    seg7_decoder u_seg7 (.bcd_in(digit_out), .seg_out(seg));

    assign pos = digit_sel;

endmodule
```

---

## 四、仿真验证

### 4.1 仿真策略

为加速仿真过程，在测试平台中使用简化的分频参数：
- `CLK_FREQ = 4`（模拟系统时钟）
- `TARGET_FREQ = 1`
- 每4个系统时钟周期完成一次数字切换

利用Python搭建了时钟精确（cycle-accurate）的行为级仿真模型，对全部模块进行了完整的功能验证。

### 4.2 仿真测试项目与结果

| 编号 | 测试项目 | 测试内容 | 结果 |
|:---:|----------|----------|:---:|
| 1 | 七段译码表验证 | 验证0~9十个数字的七段译码输出正确性 | ✓ PASS |
| 2 | 学号查找表验证 | 验证8个位置到学号数字的映射正确性 | ✓ PASS |
| 3 | 完整序列验证 | 验证2个完整循环周期（16个数字）的序列 | ✓ PASS |
| 4 | 自动循环验证 | 验证两轮序列一致性，确认自动循环功能 | ✓ PASS |
| 5 | 异步复位验证 | 验证复位后系统返回初始状态 | ✓ PASS |
| 6 | 七段译码对应验证 | 验证所有学号数字的七段译码正确性 | ✓ PASS |

### 4.3 仿真波形分析

仿真中观察到的数字显示序列：

```
复位初始状态: pos=0, digit=2  (数码管显示 "2")
t= 10ns:      pos=1, digit=0  (数码管显示 "0")
t= 50ns:      pos=2, digit=2  (数码管显示 "2")
t= 90ns:      pos=3, digit=5  (数码管显示 "5")
t=130ns:      pos=4, digit=1  (数码管显示 "1")
t=170ns:      pos=5, digit=6  (数码管显示 "6")
t=210ns:      pos=6, digit=9  (数码管显示 "9")
t=250ns:      pos=7, digit=8  (数码管显示 "8")
t=290ns:      pos=0, digit=2  (数码管显示 "2") — 自动回到初始位置
...           ...             (持续循环)
```

第一轮循环：`2 → 0 → 2 → 5 → 1 → 6 → 9 → 8`
第二轮循环：`2 → 0 → 2 → 5 → 1 → 6 → 9 → 8`

**两轮序列完全一致，验证了自动循环功能。**

### 4.4 实时仿真显示截图

仿真中每个数字对应的七段数码管ASCII可视化：

```
数字 2:           数字 0:           数字 5:           数字 1:
   ---              ---              ---              
     |            |   |            |                  
   ---                             ---              
 |                                |                  
```

```
数字 6:           数字 9:           数字 8:
   ---              ---              ---  
 |                |   |            |   | 
   ---              ---              ---  
 |   |                |            |   | 
```

### 4.5 仿真结论

经过6项全面的仿真测试，本设计全部通过验证：

1. **序列正确性**：学号20251698按序显示，顺序与学号数字一致
2. **自动循环性**：8位数字全部显示完成后自动回到初始位置，循环运行
3. **自触发特性**：系统上电（复位释放）后自动开始运行，无需任何外部触发
4. **复位功能**：异步复位可将系统恢复至初始状态
5. **译码正确性**：七段数码管译码输出正确，每个数字的段位显示无误

---

## 五、总结

本设计基于数字电路设计方法，采用自顶向下的模块化设计思路，成功实现了一个自触发学号循环显示系统。系统由时钟分频器、数字位置控制器、学号查找表和七段数码管译码器四个部分组成，全部采用Verilog HDL实现。

**系统工作流程**：
1. 系统上电后，50MHz时钟经分频器产生1Hz显示刷新时钟
2. 数字位置控制器在1Hz时钟驱动下循环产生0~7的位选信号
3. 位选信号通过学号查找表映射为对应的BCD数字
4. BCD数字经七段译码器转换为数码管段选信号
5. 数码管依次显示学号的8位数字，循环往复

**设计特点**：
- 纯硬件实现，无需软件干预
- 参数化设计，便于修改学号和显示间隔
- 模块化结构清晰，易于扩展和维护
- 自触发运行，上电即工作

---

**附录：文件清单**

| 文件路径 | 说明 |
|----------|------|
| src/clk_divider.v | 时钟分频器Verilog源码 |
| src/digit_controller.v | 数字位置控制器Verilog源码 |
| src/student_id_rom.v | 学号查找表Verilog源码 |
| src/seg7_decoder.v | 七段数码管译码器Verilog源码 |
| src/top_module.v | 顶层集成模块Verilog源码 |
| sim/tb_top_module.v | 系统仿真测试平台 |
| sim/simulate.py | Python行为级仿真验证脚本 |
