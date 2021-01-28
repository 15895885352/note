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
    start=1;
    
end



 x1spi  u0(
    .clk                (clk               )//,            .input           clk,
    .rst                (rst               )//,            .input           rst,
    .start              (               )//,//脉冲，            .input           start,//脉冲，表示参数有效
    .finish             (               )//,//脉冲，            .output          finish,//脉冲，表示data_in[7:0]有效
    .cmd                (8'h55               )//,//命令内容            .input [ 7:0]    cmd,//命令内容
    .addr               (8'h111111               )//,//地址，默            .input [23:0]    addr,//地址，默认是无效地址24'b0,
    .dummy_num          (3'd2               )//,//空            .input [ 2:0]    dummy_num,//空闲字节个数，例如：1：空闲1B
    .data_in            (               )//,//数据            .output[ 7:0]    data_in,//数据输入
    .exist_rx_data      (1'b0               )//,            .input           exist_rx_data,//存在输入的数据
    .ready              (               )//,//当前过         .output          ready,//当前过程还没结束，不要出现新的start
    .data_in            (               )//,.input           data_in,
    .sclk               (               )//,.output          sclk,
    .cs_n               (               )//,.output          cs_n,
    .data_out           (               )// .output          data_out
);






endmodule