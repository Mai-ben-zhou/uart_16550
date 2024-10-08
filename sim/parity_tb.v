`timescale 1ns/1ns
module parity_tb ();

parameter                                   data_length = 'd8          ;

reg                                         i_sys_clk                  ;
reg                                         i_sys_rst_n                ;
reg                    [data_length - 1 : 0]i_data                     ;
reg                                         i_parity_type              ;

wire                                        o_parity                   ;

initial begin
    i_sys_clk <= 1;
    i_sys_rst_n <= 0;
    i_parity_type <= 0;
    i_data <= 0;
    #20
    i_sys_rst_n <= 1;
end

initial begin
    #50 
    i_data <= 1;
    #50
    i_data <= 2;
    #50 
    i_data <= 3;
    #50
    i_data <= 4;
    #50 
    i_data <= 5;
    #50
    i_data <= 6;
    #50 
    i_data <= 7;
    #50
    i_data <= 8;
end

always  #10 i_sys_clk <= ~i_sys_clk;

parity parity_init(
    .i_sys_clk                         (i_sys_clk                 ),
    .i_sys_rst_n                       (i_sys_rst_n               ),
    .i_data                            (i_data                    ),
    .i_parity_type                     (i_parity_type             ),
    .o_parity                          (o_parity                  ) 
);

endmodule //parity_tb