module clk_switch4
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
wire    a2o;
wire    a3o;
reg     a3o_r;
reg     a3o_sync;
wire    a4o;
wire    a1i_2;
wire    a3i_2;

//------------ ����ĵ�·���� ------------------------
assign a1o = sel | a1i_2;  //A1��Ϊ�������

always @(posedge clk_A or negedge rstn_A)  
begin
	if (!rstn_A)
	begin
		a1o_r       <= 1'b0;   //��ֵ���ˣ�����0��ʾ������1��ʾ�ر�
		a1o_sync    <= 1'b0;  //Ĭ�������·�ȿ��������Գ�ֵӦΪ0 
	end
	else
	begin
		a1o_r       <= a1o;
		a1o_sync    <= a1o_r;
	end
end

assign a2o = clk_A | a2i_2;  //clk_A�ſظ�Ϊ�������

//------------- ����ĵ�·���� -----------------------------------
assign a3o = (~sel) | a3i_2;  //A3��Ϊ�������

always @(posedge clk_B or negedge rstn_B)  //�����ز�����ͬ����
begin
	if (!rstn_B)
	begin
		a3o_r       <= 1'b1; //��ֵ��Ϊ1����Ĭ�Ϲر�
		a3o_sync    <= 1'b1;
	end
	else
	begin
		a3o_r       <= a3o;
		a3o_sync    <= a3o_r;
	end
end

assign a4o = clk_B | a4i_2; //clk_B�ſظ�Ϊ���


//------------- ������·����ķ��Ų��� -----------------------------------
assign a1i_2 = ~a3o_sync;
assign a3i_2 = ~a1o_sync;


//-------------- ��Ϊ������� ----------------------------------
assign clk_out = a2o & a4o;


endmodule

