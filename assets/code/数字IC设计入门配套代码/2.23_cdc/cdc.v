module cdc
(
    input               clk1    ,
    input               rst1_n  ,

    input               clk2    ,
    input               rst2_n  ,
    
    input               vld1    ,
    input       [7:0]   dat1    ,
    
    output  reg         vld2_r  ,
    output  reg [7:0]   dat2    ,
    output              busy                 
);

//--------------------------------------------
reg                vld1_latch;
reg                vld2_latch;
reg                vld2_latch_r;
reg                vld2_latch_2r;
wire               vld2;
reg                vld2_feedback_latch;
reg                c_latch;
reg                c_latch_r;


//--------------------------------------------
//ǰ��Ĵ����뵥��������ӿ쵽���Ŀ�ʱ�Ӳ�����ȫһ��
always @(posedge clk1 or negedge rst1_n)
begin
	if (!rst1_n)
		vld1_latch <= 1'b0;
	else if (vld1)       //��vld1����תΪ��ƽ
		vld1_latch <= 1'b1;
	else if (c_latch_r) //����ʹ��ƽ����
		vld1_latch <= 1'b0;
end

always @(posedge clk2 or negedge rst2_n)
begin
	if (!rst2_n)
	begin
		vld2_latch     <= 1'b0;
		vld2_latch_r   <= 1'b0;
		vld2_latch_2r  <= 1'b0;
	end
	else
	begin
		vld2_latch     <= vld1_latch;
		vld2_latch_r   <= vld2_latch;   //��ƽ��ʱ��
		vld2_latch_2r  <= vld2_latch_r;  
	end
end

assign vld2 = vld2_latch_r & (~vld2_latch_2r); //��ȡ��ƽ�����أ����vld2

always @(posedge clk2 or negedge rst2_n)
begin
	if (!rst2_n)
		vld2_feedback_latch <= 1'b0;
	else if (vld2)
		vld2_feedback_latch <= 1'b1;  //������clk1����vld1_latch����
	else if (~vld2_latch_r)  
		vld2_feedback_latch <= 1'b0;
end

always @(posedge clk1 or negedge rst1_n)
begin
	if (!rst1_n)
	begin
		c_latch   <= 1'b0;
		c_latch_r <= 1'b0;
	end
	else
	begin
		c_latch   <= vld2_feedback_latch;
		c_latch_r <= c_latch;      //�����źŴ�clk2�絽clk1
	end
end

assign busy = vld1_latch | c_latch_r; //����æ�ź�

//��������ص㣺��clk2���ϣ���vld2����8���������ź�dat1�����Ĵ���dat2��
//�Ĵ������dat1�Ϳ����ٸ�����
always @(posedge clk2 or negedge rst2_n)
begin
	if (!rst2_n)
		dat2 <= 8'd0;
	else if (vld2)
		dat2 <= dat1;
end

always @(posedge clk2 or negedge rst2_n)
begin
	if (!rst2_n)
		vld2_r <= 1'b0;
	else 
		vld2_r <= vld2;
end


endmodule




