module  uart_rx
(
    input  wire                         i_sys_clk                  ,//系统时钟50MHz
    input  wire                         i_sys_rst_n                ,//全局复位
    input  wire                         i_rx                       ,//串口接收数据
    input  wire        [   2:0]         i_rx_uart_bps              ,//串口波特率
    input  wire                         i_rx_uart_clk              ,//串口时钟频率

    output reg         [   7:0]         o_data                     ,//串转并后的8bit数据
    output reg                          o_flag                      //串转并后的数据有效标志信号
);

//reg   define
//rx的定义
reg                                     rx_reg1                    ;//一级寄存器，打一拍，这三个寄存器是为了消除亚稳态
reg                                     rx_reg2                    ;//二级寄存器，打两拍
reg                                     rx_reg3                    ;//三级寄存器，打两拍
reg                                     start_flag_n               ;//起始位的标志信号
reg                                     work_en                    ;//有效数据的标志位（start_nedge为1时拉高，bit_cnt为有效数据个数时拉低）
reg                    [  12:0]         baud_cnt                   ;//用来判断一个有效数据的持续时间
reg                                     bit_flag                   ;//采样的标志信号，采中间的有效信号
reg                    [   3:0]         bit_cnt                    ;//只要有效信号，这个是用来计算bit_flag的个数
reg                    [   7:0]         rx_data                    ;//数据串转并
reg                                     rx_flag                    ;//输出信号的标志信号        
reg                    [  18:0]         UART_BPS                   ;//串口波特率
reg                    [  19:0]         BAUD_CNT_MAX               ;//一个bit持续多少个周期
reg                    [  29:0]         CLK_FREQ                   ;//串口时钟频率

//波特率设置
always @(*) begin
    case (i_rx_uart_bps)
        3'd0 : UART_BPS = 19'd2400;
        3'd1 : UART_BPS = 19'd4800;
        3'd2 : UART_BPS = 19'd9600;
        3'd3 : UART_BPS = 19'd19200;
        3'd4 : UART_BPS = 19'd38400;
        3'd5 : UART_BPS = 19'd57600;
        3'd6 : UART_BPS = 19'd115200;
        default: UART_BPS = 19'd9600;
    endcase   
end

//时钟设置
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    case (i_rx_uart_clk)
        0 : CLK_FREQ <= 'd26_000_000;
        1 : CLK_FREQ <= 'd50_000_000;
        default: CLK_FREQ <= 'd50_000_0000;
    endcase   
end

//计数值的最大值
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    BAUD_CNT_MAX   <=  CLK_FREQ/UART_BPS;
end

//三级缓存，消除亚稳态
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        rx_reg1 <= 0;
    end
    else
        rx_reg1 <= i_rx;
end

always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        rx_reg2 <= 0;
    end
    else
        rx_reg2 <= rx_reg1;
end

always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        rx_reg3 <= 0;
    end
    else
        rx_reg3 <= rx_reg2;
end

//start_flag_n,用来检测起始位(在rx_reg2为0，rx_reg3为1时，为高)
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        start_flag_n <= 0;
    end
    else if((!rx_reg2) && rx_reg3) begin
        start_flag_n <= 1;
    end
    else
        start_flag_n <= 0;
end

//work_en,用来标志有效数据
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        work_en <= 0;
    end
    else if(start_flag_n) begin
        work_en <= 1;
    end
    else if(bit_flag && (bit_cnt == 4'd8)) begin
        work_en <= 0;
    end
end

//baud_cnt,用来标志一个数据是否发送完毕
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        baud_cnt <= 'd0;
    end
    else if(!work_en || (baud_cnt == (BAUD_CNT_MAX - 1))) begin
        baud_cnt <= 'd0;
    end
    else if(work_en) begin
        baud_cnt <= baud_cnt + 1;
    end

end

//bit_flag,用来标志什么时候采集有效数据（在数据中间时，最稳定）
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        bit_flag <= 0;
    end
    else if(baud_cnt == (BAUD_CNT_MAX/2) - 1) begin
        bit_flag <= 1;
    end
    else
        bit_flag <= 0;
end

//bit_cnt,用来计算采集了几个有效数据
always @(posedge i_sys_clk or negedge i_sys_rst_n)  begin
    if (!i_sys_rst_n) begin
        bit_cnt <= 'd0;
    end
    else if((bit_cnt == 'd9) && bit_flag )
        bit_cnt <= 'd0;
    else if(bit_flag) begin
        bit_cnt <= bit_cnt + 1;
    end
end

//rx_data，用来串转并
always@(posedge i_sys_clk or negedge i_sys_rst_n)   begin
    if(!i_sys_rst_n) begin
        rx_data <= 'b0;
    end
    else if((bit_cnt >= 4'd1)&&(bit_cnt <= 4'd8)&&(bit_flag == 1'b1)) begin
        rx_data <= {rx_reg3, rx_data[7:1]};
    end
end


//rx_flag:输入数据移位完成时rx_flag拉高一个时钟的高电平
always@(posedge i_sys_clk or negedge i_sys_rst_n)   begin
    if(!i_sys_rst_n) begin
        rx_flag <= 0;
    end
    else    if((bit_cnt == 'd8) && bit_flag) begin
        rx_flag <= 1;
    end
    else
        rx_flag <= 0;
end


//o_data:输出完整的8位有效数据
always@(posedge i_sys_clk or negedge i_sys_rst_n)   begin
    if(!i_sys_rst_n) begin
        o_data <= 'd0;
    end
    else if(rx_flag) begin
        o_data <= rx_data;
    end
end

//o_flag:输出数据有效标志（比rx_flag延后一个时钟周期，为了和po_data同步）
always@(posedge i_sys_clk or negedge i_sys_rst_n)   begin
    if(!i_sys_rst_n) begin
        o_flag <= 0;
    end
    else
        o_flag <= rx_flag;
end

endmodule