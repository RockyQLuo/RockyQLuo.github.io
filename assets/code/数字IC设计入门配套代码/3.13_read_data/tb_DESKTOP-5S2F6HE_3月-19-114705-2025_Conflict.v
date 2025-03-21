`timescale 1ns/1ps

module tb;
//---------- ������������ ---------------------------
real            timeBai[$]      ;
real            timeBai2[$]     ;
real            dtime[$]        ;
real            dat_vector[$]   ;
integer         file            ;
integer         cnt             ;
integer         lineNum         ;

real            dat_f           ;
wire            dat             ;

//----------- ����ƽ̨���岿�� --------------------------
initial
begin
	file = $fopen("AAA.csv", "r"); //���ļ����

	//ѭ����ȡ�ļ����ݣ�ֱ���ļ���β
	cnt     = 0;
	while (!$feof(file))
	begin
		$fscanf(file, "%f,%f", timeBai[cnt], dat_vector[cnt]);
		cnt ++;
	end
	$fclose(file); //�رվ��
	lineNum = cnt; //����������

	//ת��ʱ�䵥λ����sת��Ϊns���Է���timescale��Ҫ��
	for (cnt=0; cnt<lineNum; cnt++)
	begin
		timeBai[cnt] = timeBai[cnt] * 1e9;
	end

	// �Ӿ���ʱ��timeBai�л�ȡ���ʱ��dtime
	for (cnt=0; cnt<lineNum-1; cnt++)
	begin
		timeBai2[cnt] = timeBai[cnt+1];
		dtime[cnt]    = timeBai2[cnt] - timeBai[cnt];
	end
	timeBai2.delete(); //�ͷ����õı���
	timeBai.delete();  //�ͷ����õı���

	dat_f = 0; //Ҫ������ģ�Ⲩ��
	#19e6;
	for (cnt=0; cnt<lineNum-2; cnt++)
	begin
		dat_f = dat_vector[cnt];
		#(dtime[cnt]);
	end

	$finish; //�������ݺ󣬷������
end

assign dat = dat_f > 1.65; //����߼�����ģ���ź��о�Ϊ�����ź�

endmodule

