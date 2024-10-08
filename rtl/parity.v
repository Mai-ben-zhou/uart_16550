module parity # (
    parameter   data_length = 'd8  
) 
(
    input  wire                             i_sys_clk                  ,//系统时钟50MHz
    input  wire                             i_sys_rst_n                ,//全局复位 
    input  wire        [data_length - 1 : 0]i_data                     ,
    input  wire                             i_parity_type              ,//0是偶校验，1是奇检验

    output wire                             o_parity                   //输出奇偶检验的结果
);

wire even_bit;//偶校验需求下计算出来的校验位,0说明1的个数是奇数，1说明
wire odd_bit; //奇校验需求下计算出来的校验位,0说明1的个数是偶数

assign even_bit = ^i_data;
assign odd_bit = ~even_bit;

assign o_parity = i_parity_type ? odd_bit : even_bit;


endmodule //parity
