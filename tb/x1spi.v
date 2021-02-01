`define STA_WIDTH  256
`timescale 1ns/100ps
module x1spi (
input           i_clk             ,
input           i_rst             ,
input           i_start           ,//脉冲，表示参数有效，不可连续
input [ 7:0]    i_cmd             ,//命令内容
input [23:0]    i_addr            ,//地址，默认是无效地址24'b0,
input           i_exi_addr        ,//存在地址，1:存在,
input [ 2:0]    i_dum_num         ,//空闲字节个数，例如：1：空闲1B
output[ 7:0]    o_data            ,//数据输入
input           i_exi_data        ,//存在输入|输出的数据
input [ 15:0]   i_data_num        ,//输入|输出的数据个数，例如：写整页的时候会有最多256B个数的写数据
input           i_wr_en           ,//当前是写指令
input [7:0]     wdata             ,//写的数据
output          o_rdy             ,//当前模块准备好了，可以接收新命令

input           i_si              ,//x1 spi 接口信号,
output          o_sclk            ,
output          o_cs_n            ,
output          o_so
);
//状态参数定义
// parameter IDLE       = `PAR_WIDTH'b000001,
          // SEND_CMD   = `PAR_WIDTH'b000010,
          // SEND_ADDR  = `PAR_WIDTH'b000100,
          // SEND_DUMMY = `PAR_WIDTH'b001000,
          // RX_DATA    = `PAR_WIDTH'b010000,
          // WR_DATA    = `PAR_WIDTH'b10000;
parameter IDLE       = "IDLE      ",
          SEND_CMD   = "SEND_CMD  ",
          SEND_ADDR  = "SEND_ADDR ",
          SEND_DUMMY = "SEND_DUMMY",
          RX_DATA    = "RX_DATA   ",         
          WR_DATA    = "WR_DATA   ";          
// 输入输出打拍寄存,参数信息在一个（读）命令过程中需要保持不变，
// 如果在一个（读）命令进行中，又发来新的命令，忽略新命令，必须等待当前命令执行完成。        
reg sclk=1'b0,cs_n=1'b0,so=1'b0;
reg start;
reg [ 7:0] cmd;
reg [23:0] addr;
reg [ 15:0] data_num;//代表读或写的阶段，不是专指读
reg [ 2:0] dummy_num;
reg        exi_data;
reg        exi_addr  =0;
reg        wr_en;

assign  {o_sclk,o_cs_n,o_so} = {sclk,cs_n,so};
always@(posedge i_clk or posedge i_rst) begin
    if(i_rst)  {wr_en,data_num,exi_data,start,cmd[7:0] ,addr[23:0],dummy_num,exi_addr } <= #1 {1'b0,16'b0,1'b0,1'b0,8'b0,24'b0,3'b0,1'b0};
    else if(i_start&o_rdy)     {wr_en,data_num,exi_data,start,cmd[7:0],addr[23:0],dummy_num,exi_addr } <= #1 {i_wr_en, i_data_num,i_exi_data,i_start,i_cmd[7:0],i_addr[23:0],i_dum_num,i_exi_addr };//只在start更新，防止中途变化
    else start <= #1 1'b0;
end

//标志信号产生，所有的命令都有一个通用的模板：cmd + addr + dummy + rdata
//地址不为0，表示地址有效（粗糙实现）准确的需要依据不同命令来确定是否有地址。----待修改
//dummy个数直接判断是否为0

wire exi_dummy = dummy_num !=3'b0;
reg [`STA_WIDTH-1:0] next_state,cur_state,cur_state_1d;
//准备两个计数器，bit位计数器和Byte数计数器
reg  [2:0] cnt_bit;
reg  [15:0] cnt_byte;
wire [15:0] cmd2addr_Bytenum  = 1'b1+ (exi_addr?2'd3:2'b0) ;
wire [15:0] cmd2dummy_Bytenum = cmd2addr_Bytenum + dummy_num  ;
wire [15:0] all_Bytenum       = cmd2dummy_Bytenum + (exi_data?data_num:3'b0);
//状态信号打1拍
//用以下信号检测进入某个状态的一拍，信号是脉冲。进入的条件是每个状态有一个状态指示信号，它的上升沿检测就是开始。
always@(posedge i_clk or posedge i_rst) begin if(i_rst) cur_state_1d[`STA_WIDTH-1:0] <= #1 IDLE; else    cur_state_1d[`STA_WIDTH-1:0] <= #1 cur_state[`STA_WIDTH-1:0];end
wire idle_vld      = cur_state[`STA_WIDTH-1:0] == IDLE     ;
wire send_cmd_vld  = cur_state[`STA_WIDTH-1:0] == SEND_CMD     ;
wire send_addr_vld = cur_state[`STA_WIDTH-1:0] == SEND_ADDR    ;
wire send_dumy_vld = cur_state[`STA_WIDTH-1:0] == SEND_DUMMY   ;
wire rdata_vld     = cur_state[`STA_WIDTH-1:0] == RX_DATA      ;
wire wrdata_vld    = cur_state[`STA_WIDTH-1:0] == WR_DATA      ;
reg  send_cmd_vld_1d=1'b0,send_addr_vld_1d=1'b0,send_dumy_vld_1d=1'b0,rdata_vld_1d=1'b0,wrdata_vld_1d=1'b0;
always@(posedge i_clk or posedge i_rst) begin if(i_rst) send_cmd_vld_1d  <= #1 1'b0; else    send_cmd_vld_1d  <= #1 send_cmd_vld;end
always@(posedge i_clk or posedge i_rst) begin if(i_rst) send_addr_vld_1d <= #1 1'b0; else    send_addr_vld_1d <= #1 send_addr_vld;end
always@(posedge i_clk or posedge i_rst) begin if(i_rst) send_dumy_vld_1d <= #1 1'b0; else    send_dumy_vld_1d <= #1 send_dumy_vld;end
always@(posedge i_clk or posedge i_rst) begin if(i_rst) rdata_vld_1d     <= #1 1'b0; else    rdata_vld_1d     <= #1 rdata_vld;end
always@(posedge i_clk or posedge i_rst) begin if(i_rst) wrdata_vld_1d    <= #1 1'b0; else    wrdata_vld_1d    <= #1 wrdata_vld;end
wire send_cmd_sop  = (~send_cmd_vld_1d   ) &  send_cmd_vld ;
wire send_addr_sop = (~send_addr_vld_1d  ) &  send_addr_vld;
wire send_dumy_sop = (~send_dumy_vld_1d  ) &  send_dumy_vld;
wire rdata_vld_sop = (~rdata_vld_1d      ) &  rdata_vld;
wire wrdata_vld_sop= (~wrdata_vld_1d      ) &  wrdata_vld;

//注意cur_state==SEND_ADDR条件与cur_state[2]==1是等价的。
//状态结束的判定：满足bit和Byte计数
wire send_cmd_eop  = send_cmd_vld  & (cnt_bit ==4'd7) ;
wire send_addr_eop = send_addr_vld & (cnt_bit ==4'd7) & (cnt_byte ==cmd2addr_Bytenum ) ;
wire send_dumy_eop = send_dumy_vld & (cnt_bit ==4'd7) & (cnt_byte ==cmd2dummy_Bytenum );
wire rx_data_eop   = rdata_vld     & (cnt_bit ==4'd7) & (cnt_byte ==all_Bytenum );
wire wr_data_eop   = wrdata_vld    & (cnt_bit ==4'd7) & (cnt_byte ==all_Bytenum );
wire wr_data_eop1   = wrdata_vld    & (cnt_bit ==4'd6) & (cnt_byte ==all_Bytenum );//将要停止
wire bit_cnt_start = send_cmd_sop | o_rdy;//进入状态第一次start//在o_rdy  IDLE状态不计数
//能进入到某个状态，说明最少需要计数8拍。
//bit_cnt在 首次进入某个状态bit_cnt_start|计数完成1Byte但是没有达到当前状态的终止cnt_start_inner  开始计数
//一开始就知道计数的轮数，让逻辑更加简洁
//轮数计算：cmd（1B）+ exi_addr(3B) + dummy_num (nB) + exi_data（1B）
always@(posedge i_clk or posedge i_rst) begin//准备用特殊bit表示状态
    if(i_rst) cnt_bit  <= #1 16'b1;
    else if(bit_cnt_start ) cnt_bit  <= #1 16'b1;//开始的那一拍开始计数
    else if(cnt_byte !=all_Bytenum+1'b1)  cnt_bit  <= #1 cnt_bit  + 1'b1;
end
always@(posedge i_clk or posedge i_rst) begin//只依赖cnt_bit
    if(i_rst) cnt_byte  <= #1 4'b1;
    else if(bit_cnt_start) cnt_byte  <= #1 16'b1;
    else if(cnt_bit ==3'd7)  cnt_byte  <= #1 cnt_byte  + 1'b1;//cnt_bit ==3'd7 只会出现1拍
end
//状态转移
always@(posedge i_clk or posedge i_rst) begin
    if(i_rst) cur_state[`STA_WIDTH-1:0] <= #1 IDLE;
    else    cur_state[`STA_WIDTH-1:0] <= #1 next_state[`STA_WIDTH-1:0];
end
always@(*) begin
    case(cur_state[`STA_WIDTH-1:0])
        IDLE        :    next_state[`STA_WIDTH-1:0] =start ?  SEND_CMD : IDLE;
        SEND_CMD    :
            begin
                casex({wr_en,send_cmd_eop,exi_addr,exi_dummy,exi_data})
                5'bx11xx:next_state[`STA_WIDTH-1:0] = SEND_ADDR;
                5'bx101x:next_state[`STA_WIDTH-1:0] = SEND_DUMMY;
                5'b01001:next_state[`STA_WIDTH-1:0] = RX_DATA;
                5'b11001:next_state[`STA_WIDTH-1:0] = WR_DATA;
                5'bx1000:next_state[`STA_WIDTH-1:0] = IDLE;
                default :next_state[`STA_WIDTH-1:0] = SEND_CMD;
                endcase
            end
        SEND_ADDR   :
            begin
                casex({wr_en,send_addr_eop,exi_dummy,exi_data})
                4'bx11x:next_state[`STA_WIDTH-1:0] = SEND_DUMMY;
                4'b0101:next_state[`STA_WIDTH-1:0] = RX_DATA;
                4'b1101:next_state[`STA_WIDTH-1:0] = WR_DATA;
                4'bx100:next_state[`STA_WIDTH-1:0] = IDLE;
                default:next_state[`STA_WIDTH-1:0] = SEND_ADDR;
                endcase
            end
        SEND_DUMMY  : next_state[`STA_WIDTH-1:0] = (send_dumy_eop) ?  (exi_data?   (wr_en?   WR_DATA : RX_DATA)   : IDLE) : SEND_DUMMY;  
        RX_DATA     : next_state[`STA_WIDTH-1:0] = rx_data_eop?IDLE:RX_DATA;
        WR_DATA     : next_state[`STA_WIDTH-1:0] = wr_data_eop?IDLE:WR_DATA;
        default :next_state[`STA_WIDTH-1:0] = IDLE;
    endcase
end

assign  o_rdy = cur_state[`STA_WIDTH-1:0] == IDLE;

//地址计数器
wire addr_sop = next_state==WR_DATA;
reg [15:0] addr_cnt;
always@(posedge i_clk or posedge i_rst) begin
    if(i_rst)             addr_cnt<= #1 16'b0;
    else if(addr_sop)  addr_cnt<= #1 addr;
    else if(addr_cnt==16'b0)  addr_cnt<= #1 16'b0;
    else if(addr_cnt == data_num) addr_cnt<= #1  16'b0;
    else      addr_cnt<= #1 addr_cnt + 16'b1;
end

wire [7:0]q_b_sig;
WrPageRam256x8bit	WrPageRam256x8bit_inst (
	// .clock      ( i_clk ),
	// .data_a     ( i_data_a ),
	// .address_a  ( i_address_a ),
	// .wren_a     ( i_wren_a ),
	// .q_a        ( o_q_a ),
	.clock      ( i_clk ),
	.data_a     ( 0 ),
	.address_a  ( 0 ),
	.wren_a     ( 0 ),
	.q_a        (  ),

	.address_b  ( addr_cnt ),
	.data_b     ( 0 ),
	.wren_b     ( 1'b0 ),
	.q_b        ( q_b_sig )
	);



endmodule
