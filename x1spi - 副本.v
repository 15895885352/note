`define PAR_WIDTH  6
module x1spi (
input           clk,
input           rst,
input           start,//脉冲，表示参数有效
output          finish,//脉冲，表示data_in[7:0]有效
input [ 7:0]    cmd,//命令内容
input [23:0]    addr,//地址，默认是无效地址24'b0,
input [ 2:0]    dummy_num,//空闲字节个数，例如：1：空闲1B
output[ 7:0]    data_in,//数据输入
input           exist_rx_data,//存在输入的数据
output          ready,//当前过程还没结束，不要出现新的start
//x1 spi 接口信号,
input           data_in,
output          sclk,
output          cs_n,
output          data_out
);
//状态参数定义
parameter IDLE       = `PAR_WIDTH'b000001,
          SEND_CMD   = `PAR_WIDTH'b000010,
          SEND_ADDR  = `PAR_WIDTH'b000100,
          SEND_DUMMY = `PAR_WIDTH'b001000,
          RX_DATA    = `PAR_WIDTH'b010000;
//输入输出打拍寄存          
reg sclk_reg,cs_n_reg,data_out_reg;
reg start_reg,finish_reg;
reg [ 7:0] cmd_reg;
reg [23:0] addr_reg;
reg [ 2:0] dummy_num_reg;
reg        exist_rx_data_reg;
assign  {sclk,cs_n,data_out} = {sclk_reg,cs_n_reg,data_out_reg};
always@(posedge clk or posedge rst) begin
    if(rst)  {exist_rx_data_reg,start_reg,finish_reg,cmd_reg,addr_reg,dummy_num_reg} <= {1'b0,1'b0,8'b0,24'b0,3'b0};
    else if(start&ready)     {exist_rx_data_reg,start_reg,finish_reg,cmd_reg,addr_reg,dummy_num_reg} <= {exist_rx_data,start,finish,cmd,addr,dummy_num};//只在start更新，防止中途变化
end
reg [2:0] addr_byte_num = 3'd3;//3B 长度地址
//标志信号产生
wire exist_addr = addr_reg[23:0]!=24'b0;//地址不为0，表示地址有效
wire exist_dummy = dummy_num_reg[2:0]!=3'b0;//dummy_num_reg不为0
reg [`PAR_WIDTH-1:0] next_state,current_state,current_state_1d;
reg [2:0] count_bit,count_byte;//公用计数器，最大计数8拍
always@(posedge clk or posedge rst) begin//准备用特殊bit表示状态
    if(rst) current_state_1d[5:0] <= IDLE;
    else    current_state_1d[5:0] <= current_state[5:0];
end

//注意current_state==SEND_ADDR条件与current_state[2]==1是等价的。

wire [5:0]current_state_1p = current_state[5:0] & (~current_state_1d[5:0]);
wire send_cmd_sop  = current_state_1p[1];
wire send_cmd_eop  = current_state[1] & (count_bit[2:0]==3'd7) ;//SEND_CMD & 第8拍
wire send_addr_sop = current_state_1p[2];
wire send_addr_eop = current_state[2] & (count_bit[2:0]==3'd7) & (count_byte[2:0]==addr_byte_num[2:0]) ;//是当前状态的最后一拍
wire send_addr_nsop= current_state[2] & (count_bit[2:0]==3'd0) & (count_byte[2:0]!=addr_byte_num[2:0]) ;//不是当前状态的最后一拍
wire send_dumy_sop = current_state_1p[3];
wire send_dumy_eop = current_state[3]& (count_bit[2:0]==3'd7) & (count_byte[2:0]==dummy_num_reg[2:0]);
wire send_dumy_nsop= current_state[3]& (count_bit[2:0]==3'd0) & (count_byte[2:0]!=dummy_num_reg[2:0]);
wire rx_data_sop   = current_state_1p[4];
wire rx_data_eop   = current_state[4]& (count_bit[2:0]==3'd7);

wire cnt_start = send_cmd_sop|send_addr_sop|send_dumy_sop|rx_data_sop ;//进入状态第一次start
wire cnt_start_inner = send_dumy_nsop |send_addr_nsop  ;//进入状态中间start

wire cnt_stop  = send_cmd_eop | send_addr_eop | send_dumy_eop | rx_data_eop;//
always@(posedge clk or posedge rst) begin//准备用特殊bit表示状态
    if(rst) count_bit[2:0] <= 3'b0;
    else if(cnt_start | cnt_start_inner) count_bit[2:0] <= 3'b1;//开始的那一拍开始计数
    else if(cnt_stop)  count_bit[2:0] <= 3'b0;
    else if(count_bit[2:0]!=3'b0)  count_bit[2:0] <= count_bit[2:0] + 1'b1;
end
always@(posedge clk or posedge rst) begin//只依赖count_bit
    if(rst) count_byte[2:0] <= 3'b1;
    else if(cnt_start) count_byte[2:0] <= 3'b1;
    else if(count_bit[2:0]==3'd7)  count_byte[2:0] <= count_byte[2:0] + 1'b1;//count_bit[2:0]==3'd7 只会出现1拍
end
//状态转移
always@(posedge clk or posedge rst) begin
    if(rst) current_state[5:0] <= IDLE;
    else    current_state[5:0] <= current_state[5:0];
end
always@(*) begin
    case(current_state[5:0])
        IDLE        :    next_state[5:0] =start_reg ?  SEND_CMD : IDLE;
        SEND_CMD    :
            begin
                casex({send_cmd_eop,exist_addr,exist_dummy,exist_rx_data_reg}):
                4'b11xx:next_state[5:0] = SEND_ADDR;
                4'b101x:next_state[5:0] = SEND_DUMMY;
                4'b1001:next_state[5:0] = RX_DATA;
                4'b1000:next_state[5:0] = IDLE;
                default:next_state[5:0] = SEND_CMD;
                endcase
            end
        SEND_ADDR   :
            begin
                casex({send_addr_eop,exist_dummy,exist_rx_data_reg}):
                3'b11x:next_state[5:0] = SEND_DUMMY;
                3'b101:next_state[5:0] = RX_DATA;
                3'b100:next_state[5:0] = IDLE;
                default:next_state[5:0] = SEND_ADDR;
                endcase
            end
        SEND_DUMMY  : next_state[5:0] = (exist_rx_data_reg&send_dumy_eop) ?  RX_DATA : IDLE;
        RX_DATA     : next_state[5:0] = rx_data_eop?IDLE:RX_DATA;
        default :next_state[5:0] = IDLE;
    endcase
end

endmodule
