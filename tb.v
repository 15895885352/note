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
    .start              (               )//,//���壬            .input           start,//���壬��ʾ������Ч
    .finish             (               )//,//���壬            .output          finish,//���壬��ʾdata_in[7:0]��Ч
    .cmd                (8'h55               )//,//��������            .input [ 7:0]    cmd,//��������
    .addr               (8'h111111               )//,//��ַ��Ĭ            .input [23:0]    addr,//��ַ��Ĭ������Ч��ַ24'b0,
    .dummy_num          (3'd2               )//,//��            .input [ 2:0]    dummy_num,//�����ֽڸ��������磺1������1B
    .data_in            (               )//,//����            .output[ 7:0]    data_in,//��������
    .exist_rx_data      (1'b0               )//,            .input           exist_rx_data,//�������������
    .ready              (               )//,//��ǰ��         .output          ready,//��ǰ���̻�û��������Ҫ�����µ�start
    .data_in            (               )//,.input           data_in,
    .sclk               (               )//,.output          sclk,
    .cs_n               (               )//,.output          cs_n,
    .data_out           (               )// .output          data_out
);






endmodule