`timescale 1ns/1ns
module uart_top_tb ();

reg                                     i_sys_clk                  ;//系统时钟50MHz
reg                                     i_sys_rst_n                ;//全局复位
reg                                     i_rx                       ;//串口接收数据
reg                                     i_rx_fifo_rden             ;
reg                                     i_tx_fifo_rden             ;
reg                    [   2:0]         set_bps                    ;
reg                                     set_clk_freq               ; 

wire                                    o_tx                       ;//串转并后的1bit数据
wire                                    o_finsh_flag               ; 

initial begin
    i_sys_clk = 1;
    i_sys_rst_n <= 0;
    i_rx <= 1;
    i_rx_fifo_rden <= 0;
    i_tx_fifo_rden <= 0;
    set_bps <= 2;
    set_clk_freq <= 1;
    #20
    i_sys_rst_n <= 1;
end

initial begin
    #200
    rx_bit(8'd0);
    rx_bit(8'd1);
    rx_bit(8'd2);
    rx_bit(8'd3);
    rx_bit(8'd4);
    rx_bit(8'd5);
    rx_bit(8'd6);
    rx_bit(8'd7);
    i_rx_fifo_rden = 1;
    #500
    i_rx_fifo_rden = 0;
end

initial begin
    #(5208 * 20 * 90)
    i_tx_fifo_rden <= 1;
    #20
    i_tx_fifo_rden <= 0;
end

always #10 i_sys_clk = ~i_sys_clk;


task    rx_bit(
     input  [7:0] data
);

integer i;

for (i = 0; i < 10; i = i + 1) begin
    case (i)
        0 : i_rx <= 1'b0;
        1 : i_rx <= data[0];
        2 : i_rx <= data[1];
        3 : i_rx <= data[2];
        4 : i_rx <= data[3];
        5 : i_rx <= data[4];
        6 : i_rx <= data[5];
        7 : i_rx <= data[6];
        8 : i_rx <= data[7];
        9 : i_rx <= 1'b1;            
    endcase
    #(5208 * 20);               //每bit需要的时间 
end
endtask

uart_top #(
    .DATA_WIDTH                        ('d8                       ),
    .DATA_DEPTH                        ('d128                     )
)
uart_top(
    .i_sys_clk                         (i_sys_clk                 ),
    .i_sys_rst_n                       (i_sys_rst_n               ),
    .i_rx                              (i_rx                      ),
    .i_rx_fifo_rden                    (i_rx_fifo_rden            ),
    .i_tx_fifo_rden                    (i_tx_fifo_rden            ),
    .set_bps                           (set_bps                   ),
    .set_clk_freq                      (set_clk_freq              ),

    .o_tx                              (o_tx                      ),
    .o_finsh_flag                      (o_finsh_flag              ) 
);
endmodule                                                           //uart_top_tb