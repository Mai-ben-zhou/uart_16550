module uart_top #(
    //定义fifo的数据长度和深度
    parameter                           DATA_WIDTH  = 'd8          ,
    parameter                           DATA_DEPTH  = 'd128        
)
(
    input  wire                         i_sys_clk                  ,//系统时钟50MHz
    input  wire                         i_sys_rst_n                ,//全局复位
    input  wire                         i_rx                       ,//串口接收数据
    input  wire                         i_rx_fifo_rden             ,//控制rx_fifo的读使能
    input  wire                         i_tx_fifo_rden             ,//控制tx_fifo的读使能
    input  wire        [   2:0]         set_bps                    ,//设置波特率
    input  wire                         set_clk_freq               ,//设置时钟频率                  

    output wire                         o_tx                       ,//串转并后的1bit数据
    output wire                         o_finsh_flag                //一位数据发送完毕的标志
);

//wire  define
wire                   [   7:0]         o_data                     ;
wire                                    o_flag                     ;

//rx_fifo的部分
//rx_fifo的定义
reg                                     i_rx_fifo_rst              ;//fifo复位
reg                                     i_rx_wren                  ;//写使能
reg                    [DATA_WIDTH-1:0] i_rx_wdata                 ;//写数据
reg                                     i_rx_rden                  ;//读  
wire                   [DATA_WIDTH-1:0] o_rx_rdata                 ;//读数据
wire                                    o_rx_empty                 ;//空信号
wire                                    o_rx_full                  ;//满信号
wire        [clogb2(DATA_DEPTH - 1): 0] r_rx_fifo_number           ;//fifo的内的数据量               

//控制rx_fifo的写使能
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        i_rx_wren <= 0;
        i_rx_fifo_rst <= 0;
    end
    else if(o_flag) begin
        i_rx_wren <= 1;
    end
    else
        i_rx_wren <= 0;
end

//rx_fifo输入数据的控制
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        i_rx_wdata <= 'd0;
    end
    else if(o_flag) begin
        i_rx_wdata <= o_data;
    end
    else
        i_rx_wdata <= i_rx_wdata;
end

//这里需要改进
//控制rx_fifo的读使能
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        i_rx_rden <= 0;
    end
    else if(i_rx_fifo_rden) begin
        i_rx_rden <= 1;
    end
    else if(!i_rx_fifo_rden) begin
        i_rx_rden <= 0; 
    end
    else
        i_rx_rden <= i_rx_rden;     //一启动就一直发，直到unenable信号
end

sync_fifo  #(
    .DATA_WIDTH                        (DATA_WIDTH                ),
    .DATA_DEPTH                        (DATA_DEPTH                ) 
)
rx_fifo
(
    .i_sys_clk                         (i_sys_clk                 ),
    .i_sys_rst_n                       (i_sys_rst_n               ),
    .i_fifo_rst                        (i_rx_fifo_rst             ),
    .i_wren                            (i_rx_wren                 ),
    .i_wdata                           (i_rx_wdata                ),
    .i_rden                            (i_rx_rden                 ),
    .o_rdata                           (o_rx_rdata                ),
    .o_empty                           (o_rx_empty                ),
    .o_full                            (o_rx_full                 ),
    .r_fifo_number                     (r_rx_fifo_number          ) 
);

//tx_fifo的部分
//tx_fifo的定义
reg                                     i_tx_fifo_rst              ;//fifo复位
reg                                     i_tx_wren                  ;//写使能
reg                    [DATA_WIDTH-1:0] i_tx_wdata                 ;//写数据
reg                                     i_tx_rden                  ;//读使能  
wire                   [DATA_WIDTH-1:0] o_tx_rdata                 ;//读数据
wire                                    o_tx_empty                 ;//空信号
wire                                    o_tx_full                  ;//满信号
wire        [clogb2(DATA_DEPTH - 1): 0] r_tx_fifo_number           ;//fifo的内的数据量             

//可能有错
//控制tx_fifo的写使能
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        i_tx_wren <= 0;
        i_tx_fifo_rst <= 0;
    end
    else if(i_rx_rden && r_rx_fifo_number != 'd0) begin
        i_tx_wren <= 1;
    end
    else if(!i_rx_rden) begin
        i_tx_wren <= 0;
    end
    else
        i_tx_wren <= 0;
end

//tx_fifo输入数据的控制
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        i_tx_wdata <= 'd0;
    end
    else if(i_rx_rden) begin
        i_tx_wdata <= o_rx_rdata ;
    end
    else
        i_tx_wdata <= i_tx_wdata;
end

//控制tx_fifo的读使能
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        i_tx_rden <= 0;
    end
    else if(i_tx_fifo_rden) begin       //作为启动信号
        i_tx_rden <= 1;
    end
    else if(!i_tx_fifo_rden) begin       //复位信号
        i_tx_rden <= 0; 
    end               
    else if(o_finsh_flag && r_tx_fifo_number != 'd0) begin
        i_tx_rden <= 1;
    end
    else
        i_tx_rden <= 0;                 //使得i_tx_fifo_rden只能持续一个周期
end

sync_fifo  #(
    .DATA_WIDTH                        (DATA_WIDTH                ),
    .DATA_DEPTH                        (DATA_DEPTH                ) 
)
tx_fifo
(
    .i_sys_clk                         (i_sys_clk                 ),
    .i_sys_rst_n                       (i_sys_rst_n               ),
    .i_fifo_rst                        (i_tx_fifo_rst             ),
    .i_wren                            (i_tx_wren                 ),
    .i_wdata                           (o_rx_rdata                ),
    .i_rden                            (i_tx_rden                 ),
    .o_rdata                           (o_tx_rdata                ),
    .o_empty                           (o_tx_empty                ),
    .o_full                            (o_tx_full                 ),
    .r_fifo_number                     (r_tx_fifo_number          ) 
);

//该函数是求输入整数的位宽，注意下function模块的写法
function integer clogb2(input integer number);
    begin
        for (clogb2 = 1'b0 ; number > 0 ; clogb2 = clogb2 + 1'b1) begin
            number = number >> 1;
        end
    end
endfunction

uart_rx uart_rx_init
(
    .i_sys_clk                         (i_sys_clk                 ),
    .i_sys_rst_n                       (i_sys_rst_n               ),
    .i_rx                              (i_rx                      ),
    .i_rx_uart_bps                     (set_bps                   ),
    .i_rx_uart_clk                     (set_clk_freq              ),

    .o_data                            (o_data                    ),
    .o_flag                            (o_flag                    ) 
);

uart_tx uart_tx_init
(
    .i_sys_clk                         (i_sys_clk                 ),
    .i_sys_rst_n                       (i_sys_rst_n               ),
    .i_data                            (o_tx_rdata                ),
    .i_flag                            (i_tx_rden                 ),
    .i_tx_uart_bps                     (set_bps                   ),
    .i_tx_uart_clk                     (set_clk_freq              ),

    .o_tx                              (o_tx                      ),
    .o_finsh_flag                      (o_finsh_flag              )                   
);

endmodule                                                           //uart_top