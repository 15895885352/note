`timescale 1ns/100ps
module tb (  );

reg clk =0,rst =1;
always clk =#5  ~clk;

reg start=0;

parameter TEST1_0_0_0       = 8'hA1;
parameter TEST1_0_0_1       = 8'hA2;
parameter TEST1_0_0_2       = 8'hA3;
parameter TEST1_0_0_256     = 8'hA4;
parameter TEST1_0_1_0       = 8'hA5;
parameter TEST1_0_1_1       = 8'hA6;
parameter TEST1_0_1_2       = 8'hA7;
parameter TEST1_0_1_256     = 8'hA8;
parameter TEST1_0_3_0       = 8'hA9;
parameter TEST1_0_3_1       = 8'hB0;
parameter TEST1_0_3_2       = 8'hB1;
parameter TEST1_0_3_256     = 8'hB2;
parameter TEST1_3_0_0       = 8'hB3;
parameter TEST1_3_0_1       = 8'hB4;
parameter TEST1_3_0_2       = 8'hB5;
parameter TEST1_3_0_256     = 8'hB6;
parameter TEST1_3_1_0       = 8'hB7;
parameter TEST1_3_1_1       = 8'hB8;
parameter TEST1_3_1_2       = 8'hB9;
parameter TEST1_3_1_256     = 8'hC0;
parameter TEST1_3_3_0       = 8'hC1;
parameter TEST1_3_3_1       = 8'hC2;
parameter TEST1_3_3_2       = 8'hC3;
parameter TEST1_3_3_256     = 8'hC3;

reg [7:0] par_arr [0:23];

initial  begin
    par_arr[0][7:0] = TEST1_0_0_0      ;
    par_arr[1 ][7:0] = TEST1_0_0_1      ;
    par_arr[2 ][7:0] = TEST1_0_0_2      ;
    par_arr[3 ][7:0] = TEST1_0_0_256    ;
    par_arr[4 ][7:0] = TEST1_0_1_0      ;
    par_arr[5 ][7:0] = TEST1_0_1_1      ;
    par_arr[6 ][7:0] = TEST1_0_1_2      ;
    par_arr[7 ][7:0] = TEST1_0_1_256    ;
    par_arr[8 ][7:0] = TEST1_0_3_0      ;
    par_arr[9 ][7:0] = TEST1_0_3_1      ;
    par_arr[10][7:0] = TEST1_0_3_2      ;
    par_arr[11][7:0] = TEST1_0_3_256    ;
    par_arr[12][7:0] = TEST1_3_0_0      ;
    par_arr[13][7:0] = TEST1_3_0_1      ;
    par_arr[14][7:0] = TEST1_3_0_2      ;
    par_arr[15][7:0] = TEST1_3_0_256    ;
    par_arr[16][7:0] = TEST1_3_1_0      ;
    par_arr[17][7:0] = TEST1_3_1_1      ;
    par_arr[18][7:0] = TEST1_3_1_2      ;
    par_arr[19][7:0] = TEST1_3_1_256    ;
    par_arr[20][7:0] = TEST1_3_3_0      ;
    par_arr[21][7:0] = TEST1_3_3_1      ;
    par_arr[22][7:0] = TEST1_3_3_2      ;
    par_arr[23][7:0] = TEST1_3_3_256      ;
end         

reg [7:0] cmd_uart=8'h0;
reg[23:0] addr_uart = 24'h3F0000;

wire [ 7:0]    o_cmd            ;      
wire [23:0]    o_addr           ;
wire           o_exi_addr       ;
wire [ 2:0]    o_dum_num        ;
wire           o_vld            ;
wire           o_exi_rdata      ;
wire [7:0]     o_wdata          ;
wire [15:0]    o_rdata_num      ;
wire           o_wr_en          ;

//模拟读写命令各一次
integer  i ;
initial begin
    #100;
    @(posedge clk);
    rst =0;
    for (i=0;i<24;i=i+1) begin
    #800;
    @(posedge clk); #1;  
    start=1;
    addr_uart= addr_uart+24'h10000 ;
    cmd_uart=par_arr[i][7:0];
    @(posedge clk);   #1; 
    start=0;    
    end
end
reg  [7:0]          i_data_a=0;   
reg  [7:0]          i_address_a=0;
reg                 i_wren_a=0;   
wire [7:0]          o_q_a; 
initial begin
    #120;
    @(posedge clk); #1; 
    i_data_a = 8'h00;
    i_address_a = 8'h00;
    i_wren_a = 1'd1;
    @(posedge clk); #1; 
    i_data_a = 8'h01;
    i_address_a = 8'h01;
    i_wren_a = 1'd1;
    @(posedge clk); #1; 
    i_data_a = 8'h02;
    i_address_a = 8'h02;
    i_wren_a = 1'd1;
     @(posedge clk); #1; 
    i_data_a = 8'h03;
    i_address_a = 8'h03;
    i_wren_a = 1'd1;
     @(posedge clk); #1; 
    i_data_a = 8'h04;
    i_address_a = 8'h04;
    i_wren_a = 1'd1; 
     @(posedge clk); #1; 
    i_data_a = 8'h05;
    i_address_a = 8'h05;
    i_wren_a = 1'd1;  
     @(posedge clk); #1; 
    i_data_a = 8'h05;
    i_address_a = 8'h02;
    i_wren_a = 1'd0;     

end


 x1spi  u0(
    .i_clk       (clk                ),//input           i_clk             ,
    .i_rst       (rst                ),//input           i_rst             ,
    .i_start     (start              ),//input           i_start           ,//脉冲
    .i_cmd       (o_cmd              ),//input [ 7:0]    i_cmd             ,//命令
    .i_addr      (o_addr         ),//input [23:0]    i_addr            ,//地址
    .i_exi_addr  (o_exi_addr        ),//input [23:0]    i_addr            ,//地址
    .i_dum_num   (o_dum_num              ),//input [ 2:0]    i_dum_num         ,//空闲
    .o_data      (                   ),//output[ 7:0]    o_data            ,//数据
    .i_exi_data  (o_exi_rdata               ),//input           i_exi_rdata       ,//存在
    .i_data_num  (o_rdata_num               ),//input           i_exi_rdata       ,//存在
    .i_wr_en     (o_wr_en               ),//input           i_exi_rdata       ,//存在
    .wdata       (o_wdata              ),//input           i_exi_rdata       ,//存在
    .o_rdy       (                   ),//output          o_rdy             ,//当前

    .i_si        (1'b1               ),//input           i_si              ,//x1 
    .o_sclk      (                   ),//output          o_sclk            ,
    .o_cs_n      (                   ),//output          o_cs_n            ,
    .o_so        (                   ) //output          o_so
);

 addr_trans addr_trans_u0(
.i_clk             (clk                    ),//,input                 i_clk             ,
.i_rst             (rst                    ),//,input                 i_rst             ,
.i_cmd             (cmd_uart               ),//,input       [7:0]     i_cmd             ,//外部输入的命令和地址
.i_addr            (addr_uart              ),//,input       [23:0]    i_addr            ,//地址，默认是无效地址24'b0,
.i_cmd_vld         (start                  ),//,input                 i_cmd_vld         ,//脉冲，表示参数有效

//配置写ram                              
.i_data_a          (i_data_a                   ),// input  [7:0]          i_data_a,   
.i_address_a       (i_address_a                   ),// input  [7:0]          i_address_a,
.i_wren_a          (i_wren_a                   ),// input                 i_wren_a,   
.o_q_a             (                       ),// output [7:0]          o_q_a,      

.o_wr_en           (o_wr_en                ),//input           i_exi_rdata       ,//存在
.o_cmd             (o_cmd                  ),//,output reg  [ 7:0]    o_cmd             ,//命令内容
.o_addr            (o_addr                 ),//,output reg  [23:0]    o_addr            ,//地址，默认是无效地址24'b0,
.o_exi_addr        (o_exi_addr             ),//,output reg            o_exi_addr        ,//存在地址，1:存在,
.o_dum_num         (o_dum_num              ),//,output reg  [ 2:0]    o_dum_num         ,//空闲字节个数，例如：1：空闲1B
.o_vld             (o_vld                  ),//,output reg            o_vld             ,//空闲字节个数，例如：1：空闲1B
.o_exi_data        (o_exi_rdata            ),//,output reg            o_exi_rdata       ,//存在输入的数据
.o_wdata           (o_wdata                ),//,output reg  [7:0]     o_wdata           ,//存在输入的数据
.o_data_num        (o_rdata_num            )// output reg  [15:0]    o_rdata_num        //存在输入的数据
);




endmodule