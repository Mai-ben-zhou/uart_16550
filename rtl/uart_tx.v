module  uart_tx
(
    input  wire                         i_sys_clk                  ,//系统时钟50MHz
    input  wire                         i_sys_rst_n                ,//全局复位
    input  wire        [   7:0]         i_data                     ,//模块输入的8bit数据
    input  wire                         i_flag                     ,//并行数据有效标志信号
    input  wire        [   2:0]         i_tx_uart_bps              ,//选择波特率
    input  wire                         i_tx_uart_clk              ,//选择时钟频率
 
    output reg                          o_tx                       ,//串转并后的1bit数据
    output reg                          o_finsh_flag                //串口发送完成的标志位
);

//reg   define
reg                    [  12:0]         baud_cnt                   ;//每个数据的持续时间
reg                                     bit_flag                   ;//数据的输出标志
reg                    [   3:0]         bit_cnt                    ;//数据帧的计数（2+8）
reg                                     work_en                    ;//工作的使能信号
reg                                     r_finsh_flag               ;//数据发送完成的过渡信号
reg                    [  12:0]         wait_cnt                   ;//为了数据发送时序对齐的计数
reg                    [  18:0]         UART_BPS                   ;//串口波特率
reg                    [  19:0]         BAUD_CNT_MAX               ;//一个bit需要维持多少个周期
reg                    [  29:0]         CLK_FREQ                   ;//串口的时钟频率

//波特率设置
always @(*) begin
    case (i_tx_uart_bps)
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
    case (i_tx_uart_clk)
        0 : CLK_FREQ <= 'd26_000_000;
        1 : CLK_FREQ <= 'd50_000_000;
        default: CLK_FREQ <= 'd50_000_0000;
    endcase   
end

//计数值的最大值
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    BAUD_CNT_MAX   <=  CLK_FREQ/UART_BPS;
end


//work_en:接收数据工作使能信号;
always@(posedge i_sys_clk or negedge i_sys_rst_n)   begin
    if(!i_sys_rst_n) begin
        work_en <= 0;
        r_finsh_flag <= 0;
    end
    else if(i_flag == 1)
        work_en <= 1;
    else if((bit_flag == 1'b1) && (bit_cnt == 'd9))  begin
        work_en <= 0;
        r_finsh_flag <= 1; 
    end
end

always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if(!i_sys_rst_n) begin
        wait_cnt <= 0;
    end
    else if(wait_cnt == (BAUD_CNT_MAX - 3)) begin
        o_finsh_flag <= 1;
        r_finsh_flag <= 0;
        wait_cnt <= 0;
    end
    else if(r_finsh_flag) begin
        wait_cnt <= wait_cnt + 1;
    end
    else
        o_finsh_flag <= 0;
end

//bit_flag:当baud_cnt计数器计数到1时让bit_flag拉高一个时钟的高电平
always@(posedge i_sys_clk or negedge i_sys_rst_n)   begin
    if(!i_sys_rst_n)
        bit_flag <= 0;
    else    if(baud_cnt == 'd1)
        bit_flag <= 1;
    else
        bit_flag <= 0;
end

//baud_cnt:波特率计数器计数，从0计数到BAUD_CNT_MAX - 1
always@(posedge i_sys_clk or negedge i_sys_rst_n)   begin
    if(!i_sys_rst_n)
        baud_cnt <= 'b0;
    else    if((baud_cnt == BAUD_CNT_MAX - 1) || !work_en)
        baud_cnt <= 'b0;
    else    if(work_en == 1)
        baud_cnt <= baud_cnt + 1;
end


//bit_cnt:数据位数个数计数，10个有效数据（含起始位和停止位）到来后计数器清零
always@(posedge i_sys_clk or negedge i_sys_rst_n)   begin
    if(!i_sys_rst_n)
        bit_cnt <= 'b0;
    else    if(bit_flag && (bit_cnt == 'd9))
        bit_cnt <= 'b0;
    else    if(bit_flag && work_en)
        bit_cnt <= bit_cnt + 1;
end

//tx:输出数据在满足rs232协议（起始位为0，停止位为1）的情况下一位一位输出
always@(posedge i_sys_clk or negedge i_sys_rst_n)   begin
    if(!i_sys_rst_n)
        o_tx <= 1;                                             
    else    if(bit_flag)
        case(bit_cnt)
            0       : o_tx <= 0;                  //起始位
            1       : o_tx <= i_data[0];
            2       : o_tx <= i_data[1];
            3       : o_tx <= i_data[2];
            4       : o_tx <= i_data[3];
            5       : o_tx <= i_data[4];
            6       : o_tx <= i_data[5];
            7       : o_tx <= i_data[6];
            8       : o_tx <= i_data[7];        
            9       : o_tx <= 1;                 //停止位
            default : o_tx <= 1;                 //空闲状态时为高电平
        endcase
end

endmodule