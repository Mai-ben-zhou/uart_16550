`timescale 1ns/1ns

module sync_fifo_tb ();

parameter                                   DATA_WIDTH = 4'd8          ;
parameter                                   DATA_DEPTH = 8'd128        ;

reg                                         i_sys_clk                  ;
reg                                         i_sys_rst_n                ;
reg                                         i_fifo_rst                 ;
reg                                         i_wren                     ;
reg                    [   DATA_WIDTH - 1:0]i_wdata                    ;
reg                                         i_rden                     ;

wire                   [   DATA_WIDTH - 1:0]o_rdata                    ;
wire                                        o_empty                    ;
wire                                        o_full                     ;
wire                   [7  : 0]             r_fifo_number              ;

//rst的产生
initial begin
    i_sys_clk <= 1'b0;
    i_fifo_rst <= 1'b0;
    i_sys_rst_n <= 1'b0;
    #20;
    i_sys_rst_n <= 1'b1;
end

//写操作的激励信号
initial begin
    i_wren = 0;
    i_wdata = 0;
    repeat(30) @(posedge i_sys_clk);
    i_wren = 1;
    repeat(150) @(posedge i_sys_clk)  
        i_wdata  = i_wdata + 1;
    i_wren = 0;
end

//读操作的激励信号
initial begin
    i_rden = 0;
    repeat(210) @(posedge i_sys_clk);
    i_rden = 1;
    repeat(150) @(posedge i_sys_clk);
    i_rden = 0;
end

//clk的产生
always #10 i_sys_clk = ~i_sys_clk;          //产生时钟的代码，每10个单位时间就翻转

sync_fifo 
#(
    .DATA_WIDTH (4'd8),
    .DATA_DEPTH (8'd128)
) 
sync_fifo_init(
    .i_sys_clk                         (i_sys_clk                 ),
    .i_sys_rst_n                       (i_sys_rst_n               ),
    .i_fifo_rst                        (i_fifo_rst                ),
    .i_wren                            (i_wren                    ),
    .i_wdata                           (i_wdata                   ),
    .i_rden                            (i_rden                    ),
    .o_rdata                           (o_rdata                   ),
    .o_empty                           (o_empty                   ),
    .o_full                            (o_full                    ),
    .r_fifo_number                     (r_fifo_number             ) 
);

endmodule                                                           //sync_fifo_tb