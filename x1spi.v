`define PAR_WIDTH  6
module xx (
input           clk,
input           rst,
input           start,//脉冲，表示参数有效
output          finish,//脉冲，表示data_in[7:0]有效
input [ 7:0]    cmd,//命令内容
input [23:0]    addr,//地址，默认是无效地址24'b0,
input [ 2:0]    dummy_num,//空闲字节个数，例如：1：空闲1B
output[ 7:0]    data_in,//数据输入

//x1 spi 接口信号,
input           data_in,
output          sclk,
output          cs_n,
output          data_out
);

parameter IDLE       = `PAR_WIDTH'b000001,
          SEND_CMD   = `PAR_WIDTH'b000010,
          SEND_ADDR  = `PAR_WIDTH'b000100,
          SEND_DUMMY = `PAR_WIDTH'b001000,
          RX_DATA    = `PAR_WIDTH'b010000;
reg sclk_reg,cs_n_reg,data_out_reg;
reg start_reg,finish_reg;
reg [ 7:0] cmd_reg;
reg [23:0] addr_reg;
reg [ 2:0] dummy_num_reg;
assign  {sclk,cs_n,data_out} = {sclk_reg,cs_n_reg,data_out_reg};
always@(posedge clk or posedge rst) begin 
    if(rst)  {start_reg,finish_reg,cmd_reg,addr_reg,dummy_num_reg} <= {1'b0,1'b0,8'b0,24'b0,3'b0};
    else if()     {start_reg,finish_reg,cmd_reg,addr_reg,dummy_num_reg} <= {start,finish,cmd,addr,dummy_num};
end

wire exist_addr = addr_reg[23:0]!=24'b0;//地址不为0，表示地址有效






endmodule
