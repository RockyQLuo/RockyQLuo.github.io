module clk_switch1
(
	input    clk_A   ,
	input    clk_B   ,
	input    rstn_A  ,
	input    rstn_B  ,
	input    sel     ,
	output   clk_out  
);

//------------------------------------------------
wire    a1o;
reg     a1o_r ;
reg     a1o_sync;
reg     a2i_2;
wire    a2o;
wire    a3o;
reg     a3o_r;
reg     a3o_sync;
reg     a4i_2;
wire    a4o;
wire    a1i_2;
wire    a3i_2;

//------------ ����ĵ�·���� ------------------------
assign a1o = (~sel) & a1i_2;  //A1�������

always @(posedge clk_A or negedge rstn_A)  //�����ز�����ͬ����
begin
	if (!rstn_A)
	begin
		//��Щ��ֵ��Ϊ1����Ϊ����sel��λʱΪ0����ѡ��clk_A��ΪĬ�����ʱ��
		//���������ſر����ڸ�λʱ���Ѿ���
		a1o_r       <= 1'b1;
		a1o_sync    <= 1'b1; 
	end
	else
	begin
		a1o_r       <= a1o;
		a1o_sync    <= a1o_r;
	end
end

always @(negedge clk_A or negedge rstn_A)  //�½��ز����ļĴ���
begin
	if (!rstn_A)
		a2i_2 <= 1'b1;     //��λʱĬ�ϴ�clk_A�ſ�
	else
		a2i_2 <= a1o_sync;
end

assign a2o = clk_A & a2i_2;  //clk_A�ſ�ʱ�����

//------------- ����ĵ�·���� -----------------------------------
assign a3o = sel & a3i_2;  //A3�������

always @(posedge clk_B or negedge rstn_B)  //�����ز�����ͬ����
begin
	if (!rstn_B)
	begin
		a3o_r       <= 1'b0;       //��λʱĬ�Ϲر�clk_B�ſ�
		a3o_sync    <= 1'b0;
	end
	else
	begin
		a3o_r       <= a3o;
		a3o_sync    <= a3o_r;
    end
end

always @(negedge clk_B or negedge rstn_B)  //�½��ز����ļĴ���
begin
	if (!rstn_B)
		a4i_2 <= 1'b0;
	else
		a4i_2 <= a3o_sync;
end

assign a4o = clk_B & a4i_2; //clk_B�ſ�ʱ�����

//------------- ������·����ķ��Ų��� -----------------------------------
assign a1i_2 = ~a4i_2;
assign a3i_2 = ~a2i_2;

//-------------- ������� ----------------------------------
assign clk_out = a2o | a4o;

endmodule

