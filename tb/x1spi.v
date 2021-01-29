`define STA_WIDTH  127
`timescale 1ns/100ps
module x1spi (
input           i_clk             ,
input           i_rst             ,
input           i_start           ,//���壬��ʾ������Ч
output          o_finish          ,//���壬��ʾdata_in[7:0]��Ч
input [ 7:0]    i_cmd             ,//��������
input [23:0]    i_addr            ,//��ַ��Ĭ������Ч��ַ24'b0,
input [ 2:0]    i_dum_num         ,//�����ֽڸ��������磺1������1B
output[ 7:0]    o_data            ,//��������
input           i_exi_rdata       ,//�������������
output          o_rdy             ,//��ǰ���̻�û��������Ҫ�����µ�start

input           i_si              ,//x1 spi �ӿ��ź�,
output          o_sclk            ,
output          o_cs_n            ,
output          o_so
);
//״̬��������
// parameter IDLE       = `PAR_WIDTH'b000001,
          // SEND_CMD   = `PAR_WIDTH'b000010,
          // SEND_ADDR  = `PAR_WIDTH'b000100,
          // SEND_DUMMY = `PAR_WIDTH'b001000,
          // RX_DATA    = `PAR_WIDTH'b010000;
parameter IDLE       = "IDLE      ",
          SEND_CMD   = "SEND_CMD  ",
          SEND_ADDR  = "SEND_ADDR ",
          SEND_DUMMY = "SEND_DUMMY",
          RX_DATA    = "RX_DATA   ";          
// ����������ļĴ�,������Ϣ��һ�������������������Ҫ���ֲ��䣬
// �����һ����������������У��ַ����µ�����������������ȴ���ǰ����ִ����ɡ�        
reg sclk=1'b0,cs_n=1'b0,so=1'b0;
reg start,finish;
reg [ 7:0] cmd;
reg [23:0] addr;
reg [ 2:0] dummy_num;
reg        exi_rdata;
assign  {o_sclk,o_cs_n,o_so} = {sclk,cs_n,so};
always@(posedge i_clk or posedge i_rst) begin
    if(i_rst)  {exi_rdata,start,cmd[7:0] ,addr[23:0],dummy_num[2:0]} <= #1 {1'b0,1'b0,8'b0,24'b0,3'b0};
    else if(i_start&o_rdy)     {exi_rdata,start,cmd[7:0],addr[23:0],dummy_num[2:0]} <= #1 {i_exi_rdata,i_start,i_cmd[7:0],i_addr[23:0],i_dum_num[2:0]};//ֻ��start���£���ֹ��;�仯
    else start <= #1 1'b0;
end
reg [2:0] addr_byte_num = 3'd3;
//��־�źŲ��������е������һ��ͨ�õ�ģ�壺cmd + addr + dummy + rdata
//��ַ��Ϊ0����ʾ��ַ��Ч���ֲ�ʵ�֣�׼ȷ����Ҫ���ݲ�ͬ������ȷ���Ƿ��е�ַ��----���޸�
//dummy����ֱ���ж��Ƿ�Ϊ0
wire exi_addr  = addr[23:0]!=24'b0;
wire exi_dummy = dummy_num[2:0]!=3'b0;
reg [`STA_WIDTH-1:0] next_state,cur_state,cur_state_1d;
//׼��������������bitλ��������Byte��������
reg [2:0] cnt_bit,cnt_byte;
//״̬�źŴ�1��
//�������źż�����ĳ��״̬��һ�ģ��ź������塣�����������ÿ��״̬��һ��״ָ̬ʾ�źţ����������ؼ����ǿ�ʼ��
always@(posedge i_clk or posedge i_rst) begin if(i_rst) cur_state_1d[`STA_WIDTH-1:0] <= #1 IDLE; else    cur_state_1d[`STA_WIDTH-1:0] <= #1 cur_state[`STA_WIDTH-1:0];end
wire idle_vld      = cur_state[`STA_WIDTH-1:0] == IDLE     ;
wire send_cmd_vld  = cur_state[`STA_WIDTH-1:0] == SEND_CMD     ;
wire send_addr_vld = cur_state[`STA_WIDTH-1:0] == SEND_ADDR    ;
wire send_dumy_vld = cur_state[`STA_WIDTH-1:0] == SEND_DUMMY   ;
wire rdata_vld     = cur_state[`STA_WIDTH-1:0] == RX_DATA      ;
reg  send_cmd_vld_1d=1'b0,send_addr_vld_1d=1'b0,send_dumy_vld_1d=1'b0,rdata_vld_1d=1'b0;
always@(posedge i_clk or posedge i_rst) begin if(i_rst) send_cmd_vld_1d  <= #1 1'b0; else    send_cmd_vld_1d  <= #1 send_cmd_vld;end
always@(posedge i_clk or posedge i_rst) begin if(i_rst) send_addr_vld_1d <= #1 1'b0; else    send_addr_vld_1d <= #1 send_addr_vld;end
always@(posedge i_clk or posedge i_rst) begin if(i_rst) send_dumy_vld_1d <= #1 1'b0; else    send_dumy_vld_1d <= #1 send_dumy_vld;end
always@(posedge i_clk or posedge i_rst) begin if(i_rst) rdata_vld_1d     <= #1 1'b0; else    rdata_vld_1d     <= #1 rdata_vld;end
wire send_cmd_sop  = (~send_cmd_vld_1d   ) &  send_cmd_vld ;
wire send_addr_sop = (~send_addr_vld_1d  ) &  send_addr_vld;
wire send_dumy_sop = (~send_dumy_vld_1d  ) &  send_dumy_vld;
wire rdata_vld_sop = (~rdata_vld_1d      ) &  rdata_vld;

//ע��cur_state==SEND_ADDR������cur_state[2]==1�ǵȼ۵ġ�

//״̬�������ж�������bit��Byte����
wire send_cmd_eop  = send_cmd_vld  & (cnt_bit[2:0]==3'd7) ;
wire send_addr_eop = send_addr_vld & (cnt_bit[2:0]==3'd7) & (cnt_byte[2:0]==addr_byte_num[2:0]) ;
wire send_dumy_eop = send_dumy_vld & (cnt_bit[2:0]==3'd7) & (cnt_byte[2:0]==dummy_num[2:0]);
wire rx_data_eop   = rdata_vld     & (cnt_bit[2:0]==3'd7);

wire bit_cnt_start = send_cmd_sop|send_addr_sop|send_dumy_sop|rdata_vld_sop ;//����״̬��һ��start
reg  cnt_start_inner ;//����״̬�м�start
always@(posedge i_clk or posedge i_rst) begin
    if(i_rst) cnt_start_inner <= #1 1'b0;
    else if((cnt_bit[2:0]==3'd7) & (~idle_vld) ) cnt_start_inner <= #1 1'b1;
    else cnt_start_inner <= #1 1'b0;
end

wire cnt_stop  = send_cmd_eop | send_addr_eop | send_dumy_eop | rx_data_eop;//
// wire cntbit7 = cnt_bit[2:0]==3'd7;
//�ܽ��뵽ĳ��״̬��˵��������Ҫ����8�ġ�
//bit_cnt�� �״ν���ĳ��״̬bit_cnt_start|�������1Byte����û�дﵽ��ǰ״̬����ֹcnt_start_inner  ��ʼ����
always@(posedge i_clk or posedge i_rst) begin//׼��������bit��ʾ״̬
    if(i_rst) cnt_bit[2:0] <= #1 3'b0;
    else if(bit_cnt_start | cnt_start_inner) cnt_bit[2:0] <= #1 3'b1;//��ʼ����һ�Ŀ�ʼ����
    else if(cnt_bit[2:0]!=3'b0)  cnt_bit[2:0] <= #1 cnt_bit[2:0] + 1'b1;
end
always@(posedge i_clk or posedge i_rst) begin//ֻ����cnt_bit
    if(i_rst) cnt_byte[2:0] <= #1 3'b1;
    else if(bit_cnt_start) cnt_byte[2:0] <= #1 3'b1;
    else if(cnt_bit[2:0]==3'd7)  cnt_byte[2:0] <= #1 cnt_byte[2:0] + 1'b1;//cnt_bit[2:0]==3'd7 ֻ�����1��
end
//״̬ת��
always@(posedge i_clk or posedge i_rst) begin
    if(i_rst) cur_state[`STA_WIDTH-1:0] <= #1 IDLE;
    else    cur_state[`STA_WIDTH-1:0] <= #1 next_state[`STA_WIDTH-1:0];
end
always@(*) begin
    case(cur_state[`STA_WIDTH-1:0])
        IDLE        :    next_state[`STA_WIDTH-1:0] =start ?  SEND_CMD : IDLE;
        SEND_CMD    :
            begin
                casex({send_cmd_eop,exi_addr,exi_dummy,exi_rdata})
                4'b11xx:next_state[`STA_WIDTH-1:0] = SEND_ADDR;
                4'b101x:next_state[`STA_WIDTH-1:0] = SEND_DUMMY;
                4'b1001:next_state[`STA_WIDTH-1:0] = RX_DATA;
                4'b1000:next_state[`STA_WIDTH-1:0] = IDLE;
                default:next_state[`STA_WIDTH-1:0] = SEND_CMD;
                endcase
            end
        SEND_ADDR   :
            begin
                casex({send_addr_eop,exi_dummy,exi_rdata})
                3'b11x:next_state[`STA_WIDTH-1:0] = SEND_DUMMY;
                3'b101:next_state[`STA_WIDTH-1:0] = RX_DATA;
                3'b100:next_state[`STA_WIDTH-1:0] = IDLE;
                default:next_state[`STA_WIDTH-1:0] = SEND_ADDR;
                endcase
            end
        SEND_DUMMY  : next_state[`STA_WIDTH-1:0] = (send_dumy_eop) ?  (exi_rdata?   RX_DATA : IDLE) : SEND_DUMMY;  
        RX_DATA     : next_state[`STA_WIDTH-1:0] = rx_data_eop?IDLE:RX_DATA;
        default :next_state[`STA_WIDTH-1:0] = IDLE;
    endcase
end

assign  o_rdy = cur_state[`STA_WIDTH-1:0] == IDLE;
endmodule
