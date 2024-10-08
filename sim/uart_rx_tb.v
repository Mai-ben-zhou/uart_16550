`timescale 1ns/1ns

module uart_rx_tb ();

reg                                     i_sys_clk                  ;
reg                                     i_sys_rst_n                ;
reg                                     i_rx                       ;
reg                    [   2:0]         i_rx_uart_bps              ;
reg                                     i_rx_uart_clk              ;

wire                   [   7:0]         o_data                     ;
wire                                    o_flag                     ;

initial begin
    i_sys_clk = 1;
    i_sys_rst_n <= 0;
    i_rx <= 1;
    i_rx_uart_bps <= 2;
    i_rx_uart_clk <= 1;
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
end

always #10 i_sys_clk = ~i_sys_clk;


task    rx_bit(
    input              [   7:0]         data                        
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
    #(5208 * 20);
end
endtask

uart_rx uart_rx_init
(
    .i_sys_clk                         (i_sys_clk                 ),
    .i_sys_rst_n                       (i_sys_rst_n               ),
    .i_rx                              (i_rx                      ),
    .i_rx_uart_bps                     (i_rx_uart_bps             ),
    .i_rx_uart_clk                     (i_rx_uart_clk             ),

    .o_data                            (o_data                    ),
    .o_flag                            (o_flag                    ) 
);

endmodule                                                           //uart_rx_tb