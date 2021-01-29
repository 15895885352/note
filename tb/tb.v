`timescale 1ns/100ps
module tb (  );

reg clk =0,rst =1;
always clk =#5  ~clk;

reg start=0;
initial begin
    #100;
    @(posedge clk);
    rst =0;
    #100;
    @(posedge clk);   
    start=1;
    @(posedge clk);   
    start=0;
    
end



 x1spi  u0(
    .i_clk       (clk                ),//input           i_clk             ,
    .i_rst       (rst                ),//input           i_rst             ,
    .i_start     (start              ),//input           i_start           ,//����
    .o_finish    (                   ),//output          o_finish          ,//����
    .i_cmd       (8'haa              ),//input [ 7:0]    i_cmd             ,//����
    .i_addr      (24'h555555         ),//input [23:0]    i_addr            ,//��ַ
    .i_dum_num   (3'h3               ),//input [ 2:0]    i_dum_num         ,//����
    .o_data      (                   ),//output[ 7:0]    o_data            ,//����
    .i_exi_rdata (1'b1               ),//input           i_exi_rdata       ,//����
    .o_rdy       (                   ),//output          o_rdy             ,//��ǰ

    .i_si        (1'b1               ),//input           i_si              ,//x1 
    .o_sclk      (                   ),//output          o_sclk            ,
    .o_cs_n      (                   ),//output          o_cs_n            ,
    .o_so        (                   ) //output          o_so
);






endmodule