`define STA_WIDTH  127
`timescale 1ns/100ps
//输入CMD解析对应地址需要的时序信息
module addr_trans (
input                 i_clk             ,
input                 i_rst             ,
input       [7:0]     i_cmd             ,//外部输入的命令
input       [23:0]    i_addr            ,//地址，默认是无效地址24'b0,
input                 i_cmd_vld         ,//脉冲，表示参数有效

//配置写ram
input  [7:0]          i_data_a,   
input  [7:0]          i_address_a,
input                 i_wren_a,   
output [7:0]          o_q_a,      

output                o_rdy,      
output reg            o_wr_en           ,//写使能
output reg  [ 7:0]    o_cmd             ,//命令内容
output reg  [23:0]    o_addr            ,//地址，默认是无效地址24'b0,
output reg            o_exi_addr        ,//存在地址，1:存在,
output reg  [ 2:0]    o_dum_num         ,//空闲字节个数，例如：1：空闲1B
output reg            o_vld             ,//空闲字节个数，例如：1：空闲1B
output reg            o_exi_data        ,//存在输入的数据
output reg  [7:0]     o_wdata           ,//存在输入的数据
output reg  [15:0]    o_data_num        //存在输入的数据
);

parameter WriteEnable       = 8'h06;
parameter WriteDisable      = 8'h04;
parameter ReadSR1           = 8'h05;
parameter ChipErase         = 8'h60;
parameter ManufacturerID    = 8'h90;
parameter ReadData          = 8'h03;
parameter PageProgram       = 8'h02;

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

reg [7:0]     cmd  ;    
reg [23:0]    addr ;  

// i_cmd  i_addr
// cmd    addr
// o_cmd  o_addr  addr_sop
// addr_cnt<= #1 16'b1


always@(posedge i_clk or posedge i_rst) begin
    if(i_rst)           {cmd,addr[23:0] } <= #1 {1'b0,24'b0};
    else if(i_cmd_vld)  {cmd,addr[23:0] } <= #1 {i_cmd[7:0],i_addr[23:0]};//只在 i_cmd_vld 更新，防止中途变化
end
always@(posedge i_clk or posedge i_rst)  if(i_rst) o_cmd  <= #1 8'b0; else o_cmd <= #1 cmd;

always@(posedge i_clk or posedge i_rst) begin
    if(i_rst)      begin  o_addr <= #1 24'b0;  o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'b0;  o_exi_data <= #1 1'b0; o_wr_en <= #1 1'd0;  end
    else       begin
    case (cmd)
    WriteEnable      :begin  o_addr <= #1 24'b0;  o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'b0;  o_exi_data <= #1 1'b0;o_data_num <= #1 3'd1;   end
    WriteDisable     :begin  o_addr <= #1 24'b0;  o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'b0;  o_exi_data <= #1 1'b0;o_data_num <= #1 3'd1;   end
    ReadSR1          :begin  o_addr <= #1 24'b0;  o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'b0;  o_exi_data <= #1 1'b1;o_data_num <= #1 3'd1;   end
    ChipErase        :begin  o_addr <= #1 24'b0;  o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'b0;  o_exi_data <= #1 1'b0;o_data_num <= #1 3'd1;   end
    ManufacturerID   :begin  o_addr <= #1 24'b0;  o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'd2;  o_exi_data <= #1 1'b1;o_data_num <= #1 3'd3;    end
    ReadData         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b1;  o_dum_num  <= #1 3'd0;  o_exi_data <= #1 1'b1;o_data_num <= #1 3'd1;o_wr_en <= #1 1'd0;    end
    PageProgram      :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b1;  o_dum_num  <= #1 3'd0;  o_exi_data <= #1 1'b1;o_data_num <= #1 3'd2;o_wr_en <= #1 1'd1;    end
    
    //写
    TEST1_0_0_0         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'd0;  o_exi_data <= #1 1'b0;o_data_num <= #1 16'd0   ;o_wr_en <= #1 1'd1;    end
    TEST1_0_0_1         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'd0;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd1   ;o_wr_en <= #1 1'd1;    end
    TEST1_0_0_2         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'd0;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd2   ;o_wr_en <= #1 1'd1;    end
    TEST1_0_0_256       :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'd0;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd256 ;o_wr_en <= #1 1'd1;    end
    TEST1_0_1_0         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'd1;  o_exi_data <= #1 1'b0;o_data_num <= #1 16'd0   ;o_wr_en <= #1 1'd1;    end
    TEST1_0_1_1         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'd1;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd1   ;o_wr_en <= #1 1'd1;    end
    TEST1_0_1_2         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'd1;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd2   ;o_wr_en <= #1 1'd1;    end
    TEST1_0_1_256       :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'd1;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd256 ;o_wr_en <= #1 1'd1;    end
    TEST1_0_3_0         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'd3;  o_exi_data <= #1 1'b0;o_data_num <= #1 16'd0   ;o_wr_en <= #1 1'd1;    end
    TEST1_0_3_1         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'd3;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd1   ;o_wr_en <= #1 1'd1;    end
    TEST1_0_3_2         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'd3;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd2   ;o_wr_en <= #1 1'd1;    end
    TEST1_0_3_256       :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'd3;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd256 ;o_wr_en <= #1 1'd1;    end
    TEST1_3_0_0         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b1;  o_dum_num  <= #1 3'd0;  o_exi_data <= #1 1'b0;o_data_num <= #1 16'd0   ;o_wr_en <= #1 1'd1;    end
    TEST1_3_0_1         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b1;  o_dum_num  <= #1 3'd0;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd1   ;o_wr_en <= #1 1'd1;    end
    TEST1_3_0_2         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b1;  o_dum_num  <= #1 3'd0;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd2   ;o_wr_en <= #1 1'd1;    end
    TEST1_3_0_256       :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b1;  o_dum_num  <= #1 3'd0;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd256 ;o_wr_en <= #1 1'd1;    end
    TEST1_3_1_0         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b1;  o_dum_num  <= #1 3'd1;  o_exi_data <= #1 1'b0;o_data_num <= #1 16'd0   ;o_wr_en <= #1 1'd1;    end
    TEST1_3_1_1         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b1;  o_dum_num  <= #1 3'd1;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd1   ;o_wr_en <= #1 1'd1;    end
    TEST1_3_1_2         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b1;  o_dum_num  <= #1 3'd1;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd2   ;o_wr_en <= #1 1'd1;    end
    TEST1_3_1_256       :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b1;  o_dum_num  <= #1 3'd1;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd256 ;o_wr_en <= #1 1'd1;    end
    TEST1_3_3_0         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b1;  o_dum_num  <= #1 3'd3;  o_exi_data <= #1 1'b0;o_data_num <= #1 16'd0   ;o_wr_en <= #1 1'd1;    end
    TEST1_3_3_1         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b1;  o_dum_num  <= #1 3'd3;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd1   ;o_wr_en <= #1 1'd1;    end
    TEST1_3_3_2         :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b1;  o_dum_num  <= #1 3'd3;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd2   ;o_wr_en <= #1 1'd1;    end
    TEST1_3_3_256       :begin  o_addr <= #1 addr;   o_exi_addr <= #1 1'b1;  o_dum_num  <= #1 3'd3;  o_exi_data <= #1 1'b1;o_data_num <= #1 16'd256 ;o_wr_en <= #1 1'd1;    end

    default: begin  o_addr <= #1 24'b0;  o_exi_addr <= #1 1'b0;  o_dum_num  <= #1 3'b0;  o_exi_data <= #1 1'b0;   end
    endcase
    end
end

// wire [3:0]wait_num = 1'b1+o_dum_num +(o_exi_addr?3'b3:3'b0);





WrPageRam256x8bit	WrPageRam256x8bit_inst (
	.clock      ( i_clk ),
	.data_a     ( i_data_a ),
	.address_a  ( i_address_a ),
	.wren_a     ( i_wren_a ),
	.q_a        ( o_q_a ),

	.address_b  ( address_b_sig ),
	.data_b     ( data_b_sig ),
	.wren_b     ( 1'b0 ),
	.q_b        ( q_b_sig )
	);

endmodule

