module sync_fifo #(
    parameter                           DATA_WIDTH = 4'd8          ,//一次存进fifo的数据大小
    parameter                           DATA_DEPTH = 8'd128         //整个FIFO可以存几个8位数据数据
)
(
    input  wire                                     i_sys_clk                  ,//系统时钟
    input  wire                                     i_sys_rst_n                ,//系统复位
    input  wire                                     i_fifo_rst                 ,//fifo复位
    input  wire                                     i_wren                     ,//写使能
    input  wire        [DATA_WIDTH-1:0]             i_wdata                    ,//写数据
    input  wire                                     i_rden                     ,//读使能
            
    output wire        [DATA_WIDTH-1:0]             o_rdata                    ,//读数据
    output wire                                     o_empty                    ,//空信号
    output wire                                     o_full                     ,//写信号
    output reg         [clogb2(DATA_DEPTH - 1): 0]  r_fifo_number  //fifo的内的数据量               
);

//定义ram的深度(即定义了一个数组)
reg                    [DATA_WIDTH - 1 : 0]    mem_ram     [0 : DATA_DEPTH - 1]                           ;

//定义读写fifo指针
reg                    [clogb2(DATA_DEPTH - 1) - 1 : 0]r_wr_ptr                   ;//写指针
reg                    [clogb2(DATA_DEPTH - 1) - 1 : 0]r_rd_ptr                   ;//读指针

//写指针操作——写使能拉高且未满时，地址加一
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        r_wr_ptr <= 'b0;
    end
    else if(i_fifo_rst) begin
        r_wr_ptr <= 'b0;
    end
    else if(i_wren && !o_full) begin
        r_wr_ptr <= r_wr_ptr + 1'b1;
    end
    else
        r_wr_ptr <= r_wr_ptr;
end
 
//读指针操作——读使能拉高且未空时，地址加一
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        r_rd_ptr <= 'b0;
    end
    else if(i_fifo_rst) begin
        r_rd_ptr <= 'b0;
    end
    else if(i_rden && !o_empty) begin
        r_rd_ptr <= r_rd_ptr + 1'b1;
    end
    else
        r_rd_ptr <= r_rd_ptr;
end

//读操作
reg                    [DATA_WIDTH - 1 : 0]r_rdata                    ;
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        r_rdata <= 'd0;
    end
    else if(i_rden && !o_empty) begin
        r_rdata <= mem_ram[r_rd_ptr];
    end
end

//写操作
integer i;
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin                                         //初始化，数组清零
        for (i = 0; i < DATA_DEPTH; i = i + 1) begin
            mem_ram[i] <= 'd0;
        end
    end
    else if(i_wren && !o_full) begin
        mem_ram[r_wr_ptr] <= i_wdata;
    end
end

//计算FIFO存的数量
always @(posedge i_sys_clk or negedge i_sys_rst_n) begin
    if (!i_sys_rst_n) begin
        r_fifo_number <= 'd0;
    end
    else if(i_rden && i_wren && !o_empty && !o_full) begin
        r_fifo_number <= r_fifo_number;
    end
    else if(i_rden && !i_wren && !o_empty) begin
        r_fifo_number <= r_fifo_number - 1'b1;
    end
    else if(!i_rden && i_wren && !o_full) begin
        r_fifo_number <= r_fifo_number + 1'b1;
    end
    else
        r_fifo_number <= r_fifo_number;
end

assign o_rdata = r_rdata;
assign o_full  = (r_fifo_number == DATA_DEPTH) ? 1 : 0;
assign o_empty = (r_fifo_number == 'd0) ? 1 : 0;
//assign fifo_number = r_fifo_number;

//该函数是求输入整数的位宽，注意下function模块的写法
function integer clogb2(input integer number);
    begin
        for (clogb2 = 1'b0 ; number > 0 ; clogb2 = clogb2 + 1'b1) begin
            number = number >> 1;
        end
    end
endfunction

endmodule