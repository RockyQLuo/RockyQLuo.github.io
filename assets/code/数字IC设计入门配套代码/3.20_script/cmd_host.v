module cmd_host
(
	output  logic   [4:0]   a   ,
	output  logic           b       
);

//--------------------------------------
int             fp;
string          str; //�ַ�������
string          cmd_name, cmd_param; //�ַ�������
logic   [7:0]   param_a;
logic   [7:0]   param_b;
logic   [7:0]   cc;
int             have_param;
int             ii;

//-----------------------------------------------------
initial 
begin
	fp = $fopen("cmd.txt", "r"); //�򿪿��ƽű�

	while($fgets(str, fp)) //��ȡ�ű���ÿһ�е��ַ���
	begin
		cc = str.getc(0); //��str�л�ȡ��һ���ַ�
		ii = 0;
		have_param = 0;
		cmd_name  = "";
		cmd_param = "";

		while (cc != 0) //�жϸ��ַ����ǿ��ַ���0������ַ�
		begin
			//�������ƺͲ����ÿո�ֿ���ǰ�������ƣ������ǲ���
			if (cc == " ") 
			begin
				//�������
				$sscanf(str.substr(0,ii-1),"%s",cmd_name);
				//��ò���������ii+1�������ַ�
				cmd_param = str.substr(ii+1); 
				have_param = 1; //��ʾ�������������
				break;  //����whileѭ��
			end 
			else //û�������ָ��Ŀո�ʱ����һֱ��Ѱ
			begin
				ii++;
				cc = str.getc(ii);
			end
		end

		if (have_param == 0) //��û�в�����˵�����������������
		begin
			$sscanf(str, "%s", cmd_name);
			cmd_param = "";
		end

		case(cmd_name)  //�����б�
			"AAA": 
			begin
				//��ȡ����
				$sscanf(cmd_param, "%d %d",param_a, param_b); 
				//ִ�����task
				task_aaa(param_a, param_b);
			end

			"BBB": 
			begin
				//��ȡ����
				$sscanf(cmd_param, "%d", param_a);
				task_bbb(param_a);  //ִ�����task
			end

			"WAIT":
			begin
				//��ȡ����
				$sscanf(cmd_param, "%d", param_a);
				#(param_a); //ִ��
			end

			"DONE":
			begin
				$finish; //û�в�����ֱ��ִ��
			end
		endcase
	end
end

initial //�źų�ʼ��
begin
	a = 0;
	b = 1'b0;
end

task task_aaa;
	input   [3:0]   x1;
	input   [3:0]   x2;

	a = x1 + x2;
endtask

task task_bbb;
	input   sig ;

	b = sig;
endtask

endmodule

