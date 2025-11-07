module Count_256 (
    input            i_clk,
    input            i_ready,
    input  [255:0]   i_value,
    output           o_ready,
    output  [15:0]   o_value
    );

logic [15:0] Value_Temp_00;
logic [15:0] Value_Temp_01;
logic [15:0] Value_Temp_02;
logic [15:0] Value_Temp_03;
logic [15:0] Value_Temp_04;
logic [15:0] Value_Temp_05;
logic [15:0] Value_Temp_06;
logic [15:0] Value_Temp_07;
logic [15:0] Value_Temp_08;
logic [15:0] Value_Temp_09;
logic [15:0] Value_Temp_10;
logic [15:0] Value_Temp_11;
logic [15:0] Value_Temp_12;
logic [15:0] Value_Temp_13;
logic [15:0] Value_Temp_14;
logic [15:0] Value_Temp_15;

// 将256位的输入分别切分为16个16位段
assign Value_Temp_00 = i_value[15:0];
assign Value_Temp_01 = i_value[31:16];
assign Value_Temp_02 = i_value[47:32];
assign Value_Temp_03 = i_value[63:48];
assign Value_Temp_04 = i_value[79:64];
assign Value_Temp_05 = i_value[95:80];
assign Value_Temp_06 = i_value[111:96];
assign Value_Temp_07 = i_value[127:112];
assign Value_Temp_08 = i_value[143:128];
assign Value_Temp_09 = i_value[159:144];
assign Value_Temp_10 = i_value[175:160];
assign Value_Temp_11 = i_value[191:176];
assign Value_Temp_12 = i_value[207:192];
assign Value_Temp_13 = i_value[223:208];
assign Value_Temp_14 = i_value[239:224];
assign Value_Temp_15 = i_value[255:240];

logic [7:0] Result_Temp_00;
logic [7:0] Result_Temp_01;
logic [7:0] Result_Temp_02;
logic [7:0] Result_Temp_03;
logic [7:0] Result_Temp_04;
logic [7:0] Result_Temp_05;
logic [7:0] Result_Temp_06;
logic [7:0] Result_Temp_07;
logic [7:0] Result_Temp_08;
logic [7:0] Result_Temp_09;
logic [7:0] Result_Temp_10;
logic [7:0] Result_Temp_11;
logic [7:0] Result_Temp_12;
logic [7:0] Result_Temp_13;
logic [7:0] Result_Temp_14;
logic [7:0] Result_Temp_15;

// 新增：子模块就绪信号数组，记录每个Count_16是否完成
logic [15:0] SubModule_Ready;
// 所有子模块都就绪时，该信号为高
logic All_SubModule_Ready;
assign All_SubModule_Ready = &SubModule_Ready;

// 新增：延迟寄存器，用于对齐o_ready时序
logic [3:0] Ready_Delay;
logic [15:0] Sum_Result;

// 实例化16个Count_16子模块，连接o_ready到SubModule_Ready
Count_16  u_Count_16_00 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_00),
    .o_ready  (SubModule_Ready[0]),
    .o_value  (Result_Temp_00)
);

Count_16  u_Count_16_01 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_01),
    .o_ready  (SubModule_Ready[1]),
    .o_value  (Result_Temp_01)
);

Count_16  u_Count_16_02 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_02),
    .o_ready  (SubModule_Ready[2]),
    .o_value  (Result_Temp_02)
);

Count_16  u_Count_16_03 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_03),
    .o_ready  (SubModule_Ready[3]),
    .o_value  (Result_Temp_03)
);

Count_16  u_Count_16_04 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_04),
    .o_ready  (SubModule_Ready[4]),
    .o_value  (Result_Temp_04)
);

Count_16  u_Count_16_05 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_05),
    .o_ready  (SubModule_Ready[5]),
    .o_value  (Result_Temp_05)
);

Count_16  u_Count_16_06 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_06),
    .o_ready  (SubModule_Ready[6]),
    .o_value  (Result_Temp_06)
);

Count_16  u_Count_16_07 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_07),
    .o_ready  (SubModule_Ready[7]),
    .o_value  (Result_Temp_07)
);

Count_16  u_Count_16_08 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_08),
    .o_ready  (SubModule_Ready[8]),
    .o_value  (Result_Temp_08)
);

Count_16  u_Count_16_09 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_09),
    .o_ready  (SubModule_Ready[9]),
    .o_value  (Result_Temp_09)
);

Count_16  u_Count_16_10 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_10),
    .o_ready  (SubModule_Ready[10]),
    .o_value  (Result_Temp_10)
);

Count_16  u_Count_16_11 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_11),
    .o_ready  (SubModule_Ready[11]),
    .o_value  (Result_Temp_11)
);

Count_16  u_Count_16_12 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_12),
    .o_ready  (SubModule_Ready[12]),
    .o_value  (Result_Temp_12)
);

Count_16  u_Count_16_13 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_13),
    .o_ready  (SubModule_Ready[13]),
    .o_value  (Result_Temp_13)
);

Count_16  u_Count_16_14 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_14),
    .o_ready  (SubModule_Ready[14]),
    .o_value  (Result_Temp_14)
);

Count_16  u_Count_16_15 (
    .i_clk    (i_clk),
    .i_ready  (i_ready),
    .i_value  (Value_Temp_15),
    .o_ready  (SubModule_Ready[15]),
    .o_value  (Result_Temp_15)
);

// 时序逻辑：等待所有子模块就绪后，计算求和结果
always @(posedge i_clk) begin
    if (All_SubModule_Ready) begin
        Sum_Result <= Result_Temp_00 + Result_Temp_01 + Result_Temp_02 + Result_Temp_03 +
                      Result_Temp_04 + Result_Temp_05 + Result_Temp_06 + Result_Temp_07 +
                      Result_Temp_08 + Result_Temp_09 + Result_Temp_10 + Result_Temp_11 +
                      Result_Temp_12 + Result_Temp_13 + Result_Temp_14 + Result_Temp_15;
    end
    // 延迟就绪信号，确保Sum_Result稳定后再输出（延迟级数可根据实际需求调整）
    Ready_Delay <= {Ready_Delay[2:0], All_SubModule_Ready};
end

// 输出就绪信号：取延迟后的结果，确保时序对齐
assign o_ready = Ready_Delay[3];
// 输出最终的汉明距离结果
assign o_value = Sum_Result;

endmodule