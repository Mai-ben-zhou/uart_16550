`timescale 1ns/1ns

module uart_tx_tb ();

reg                                     i_sys_clk                  ;//系统时钟50MHz
reg                                     i_sys_rst_n                ;//全局复位
reg                    [   7:0]         i_data                     ;//模块输入的8bit数据
reg                                     i_flag                     ;//并行数据reg
reg                    [   2:0]         i_tx_uart_bps              ;
reg                                     i_tx_uart_clk              ; 

wire                                    o_tx                       ;//串转并后的1bit数据
wire                                    o_finsh_flag               ;//传完一个数据的标志


initial begin
    i_sys_clk = 1;
    i_sys_rst_n <= 0;
    i_tx_uart_bps <= 2;
    i_tx_uart_clk <= 1;
    #20;
    i_sys_rst_n <= 1;
end

initial begin
    //初始化
    i_data <= 8'b0;
    i_flag <= 1'b0;
    #200
    //发送数据0
    i_data <= 8'd0;
    i_flag <= 1'b1;
    #20
    i_flag <= 1'b0;
    #(5208*20*10);
//每发送1bit数据需要5208个时钟周期，一帧数据为10bit
//所以需要数据延时(5208*20*10)后再产生下一个数据
    //发送数据1
    i_data <= 8'd1;
    i_flag <= 1'b1;
    #20
    i_flag <= 1'b0;
    #(5208*20*10);
    //发送数据2
    i_data <= 8'd2;
    i_flag <= 1'b1;
    #20
    i_flag <= 1'b0;
    #(5208*20*10);
    //发送数据3
    i_data <= 8'd3;
    i_flag <= 1'b1;
    #20
    i_flag <= 1'b0;
    #(5208*20*10);
    //发送数据4
    i_data <= 8'd4;
    i_flag <= 1'b1;
    #20
    i_flag <= 1'b0;
    #(5208*20*10);
    //发送数据5
    i_data <= 8'd5;
    i_flag <= 1'b1;
    #20
    i_flag <= 1'b0;
    #(5208*20*10);
    //发送数据6
    i_data <= 8'd6;
    i_flag <= 1'b1;
    #20
    i_flag <= 1'b0;
    #(5208*20*10);
    //发送数据7
    i_data <= 8'd7;
    i_flag <= 1'b1;
    #20
    i_flag <= 1'b0;
end

always #10 i_sys_clk <= ~i_sys_clk;

uart_tx  uart_tx_init
(
    .i_sys_clk                         (i_sys_clk                 ),
    .i_sys_rst_n                       (i_sys_rst_n               ),
    .i_data                            (i_data                    ),
    .i_flag                            (i_flag                    ),
    .i_tx_uart_bps                     (i_tx_uart_bps             ),
    .i_tx_uart_clk                     (i_tx_uart_clk             ),
    .o_tx                              (o_tx                      ),
    .o_finsh_flag                      (o_finsh_flag              )            
);
endmodule                                                           //uart_tx_tb