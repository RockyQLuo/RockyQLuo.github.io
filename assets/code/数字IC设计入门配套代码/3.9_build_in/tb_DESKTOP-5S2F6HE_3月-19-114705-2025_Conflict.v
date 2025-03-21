`timescale    1ns/1ps    //��������

//����TBģ�飬�������������֣���tb����tbΪǰ׺�����ƽ�Ϊ�������������ڱ���
//tbû�ж���ӿڲ��������ж�����������tb�ڲ������tb����ֱ��ʹ�÷ֺŹر�
module tb;
//------------  �ڲ���������    --------------------
int                 fsdbDump    ;
logic				clk			;
logic				rst_n		;

logic				trig		;

real				z			;
logic	    [16:0]	z_fix		;
wire				vld			;//����DUT���κ�ģ����������wire

wire signed	[11:0]	atany		;
real				atany_real	;
real				atany_get	;

real				err_atan	;
real				max_err		;

//------------    ��������    --------------------
initial
begin
    $fsdbDumpfile("tb.fsdb");
    $fsdbDumpvars(0);
end

//����ʱ�ӣ���������32MHz
initial
begin
	clk = 1'b0;
	forever
	begin
		#(1e9/(2.0*32e6)) clk = ~clk;
	end
end

//���ɸ�λ�źţ�����1ms���⸴λ����1e6ns��
initial
begin
	rst_n = 1'b0;
	#1e6  rst_n = 1'b1;
end

//��Ҫ�ļ���Դģ��
initial
begin
	//��ʼ������������
	trig = 1'b0;
	z = -255;
	z_fix = 1'b0;

	//�ȵ��⸴λ���ٵ�10us
	@(posedge rst_n);
	#10e3;

	//���������ձ�׼������-255~255������Ϊ1/256����Ӧ������������ȷ����Ϊͨ��
	//��ˣ����ﰴҪ�󣬽���whileѭ������ʱ�ֲ����켤��
	z = -255;
	while (z <= 255)
	begin
		//��̽�⵽һ��ʱ�������غ󣬾�triggerһ��DUT������DUT��ʼ����
		@(posedge clk); trig <= 1'b1;

		//trigger��ͬʱ����������z_fixҲҪ׼����
		//���ｫz����256����Ϊz_fix��z�Ķ��㻯��z��С�����ֱ�����Ϊ8λ
		z_fix <= int'(z*256);

		//�����뽫trig����Ϊ�����źţ���ˣ�����һ��ʱ���أ�trig����ȥ
		@(posedge clk); trig <= 1'b0;

		//�ȴ�������ɣ���DUT�������ʱ��vld����һ�������źţ�����ֹͣ
		wait(vld);

		//�ϴ�������ɺ��500ns���������ݸ��£����ٵ�500ns
		#5e2 z = z + 1/256.0;
		#5e2;
	end

	//��ȫ������������ɣ��Ҽ���Ҳ��ɺ��ٵ�1us����������
	#1e3 $finish;
end

//�����ǲο�ģ��
//ʹ��always���൱��ʹ��initial��forever��������ͬ
always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	begin
		atany_get  <= -1.56;
		atany_real <= 0;
	end
	else
	begin
		//DUT��������atany�Ƕ��㻯��ĸ���������Ҫ��tb�лָ�Ϊ������
		//�ָ��ĸ���������atany_get������1024����Ϊԭ����Ϊ10����С������
		//atany_real�������Ķ�����
		//tb�лὫatany_get��atany_real���ж���
		//ÿ�������������󣬾͸���һ��
		if (vld)
		begin
			//������Ҫǿ��ת��Ϊ����������
			atany_get  <= real'(atany)/1024; 
			atany_real <= $atan(z); //ʹ���ڽ����������׼��
		end
	end
end

//����DUT�����ο��𰸵Ĳ�𣬲�ȡ����ֵ���㷨�в��������ķ��ţ�ֻ���ľ���ֵ
assign err_atan = $abs(atany_real - atany_get);

//�Զ�Ѱ�Ҵ�������ֵ����������
always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		max_err <= 0;
	else
	begin
		//ÿ����������󣬾ͻ������������
		if (vld)
		begin
			//���#1�ӳٺ���Ҫ�������д�Ļ����˿���û�����
			//�����������ӳ�һ�£��ȴ����������
			//tb����Ӳ����û�м����ӳ�
			//��˼�����˲����ɵģ�����д#0.001Ҳ����
			#1;
			if (err_atan > max_err)
				max_err <= err_atan;
		end
	end
end

//����DUT
atan    u_atan
(
	.clk     (clk	),//i
	.rst_n   (rst_n	),//i

	.trig    (trig	),//i�����㴥������
	.vld     (vld	),//o����������Ч����

	.para_in (z_fix	),//i[16:0]���з��ţ�8λ������8λС��
	.atany   (atany	) //i[11:0]���з��ţ�1λ������10λС��
);

endmodule

