module clk_switch2
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
reg     a1o_sync_r;
wire    a2o;
wire    a3o;
reg     a3o_r;
reg     a3o_sync;
reg     a3o_sync_r;
wire    a4o;
wire    a1i_2;
wire    a3i_2;

//------------ ����ĵ�·���� ------------------------
assign a1o = (~sel) & a1i_2;  //A1�������

always @(posedge clk_A or negedge rstn_A)  //���л���·һ��ͬ
begin
	if (!rstn_A)
	begin
		a1o_r    <= 1'b1;    //��λʱĬ�ϴ�clk_A�ſ�
		a1o_sync <= 1'b1;   
	end                       
	else
	begin
		a1o_r    <= a1o;
		a1o_sync <= a1o_r;
	end
end

always @(posedge clk_A or negedge rstn_A)  //S3��ע�������Ϊ���������߼�
begin
	if (!rstn_A)
		a1o_sync_r <= 1'b1;
	else
		a1o_sync_r <= a1o_sync;
end

ICG    u_ICG_A        //����ICG������ſ�ʱ��a2o
(
	.en         (a1o_sync ),
	.clk_in     (clk_A    ),
	.clk_out    (a2o      )
);

//------------- ����ĵ�·���� -----------------------------------
assign a3o = sel & a3i_2;  //A3�������

always @(posedge clk_B or negedge rstn_B)  //���л���·һ��ͬ
begin
	if (!rstn_B)
	begin
		a3o_r     <= 1'b0;       //��λʱĬ�Ϲر�clk_B�ſ�
		a3o_sync  <= 1'b0;
	end
	else
	begin
		a3o_r    <= a3o;
		a3o_sync <= a3o_r;
	end
end

always @(posedge clk_B or negedge rstn_B)  //S6��ע�������Ϊ���������߼�
begin
	if (!rstn_B)
		a3o_sync_r <= 1'b0;
	else
		a3o_sync_r <= a3o_sync;
end

ICG    u_ICG_B        //����ICG������ſ�ʱ��a4o
(
	.en         (a3o_sync ),
	.clk_in     (clk_B    ),
	.clk_out    (a4o      ) 
);


//------------- ������·����ķ��Ų��� -----------------------------------
assign a1i_2 = ~a3o_sync_r;
assign a3i_2 = ~a1o_sync_r;

//-------------- ������� ----------------------------------
assign clk_out = a2o | a4o;

endmodule

