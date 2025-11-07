module Match_Distance (
    input              i_clk,
    input	    	   i_value_ready,
    input	[255:0]	   i_value_0,   // 图1描述符
    input	[255:0]	   i_value_1,   // 图2描述符
    output             o_ready,
    output  [15:0]     o_value
);

// 关键参数：汉明距离阈值（256位ORB推荐32~40，需根据场景调试）
parameter HAMMING_THRESHOLD = 16'd34;

logic Value_Ready = 1'b0;
logic [255:0] Value_Temp = {256{1'b0}};

// 1. 异或计算差异位（不同位为1，相同位为0）
always @(posedge i_clk) begin
    if (i_value_ready) begin
        Value_Temp <= i_value_0 ^ i_value_1;
        Value_Ready <= 1'b1;
    end else begin
        Value_Temp <= {256{1'b0}};
        Value_Ready <= 1'b0;
    end
end

// 2. 统计差异位个数（汉明距离）
logic count_ready;
logic [15:0] real_hamming_dist;
Count_256  u_Coun_256 (
    .i_clk     ( i_clk         ),
    .i_ready   ( Value_Ready   ),
    .i_value   ( Value_Temp    ),
    .o_ready   ( count_ready   ),
    .o_value   ( real_hamming_dist )
);

// 3. 阈值过滤：有效距离输出真实值，无效输出最大值（上层会自动忽略）
assign o_ready = count_ready;
assign o_value = (real_hamming_dist <= HAMMING_THRESHOLD) ? real_hamming_dist : 16'hFFFF;

endmodule