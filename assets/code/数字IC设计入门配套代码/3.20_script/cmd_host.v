module cmd_host
(
	output  logic   [4:0]   a   ,
	output  logic           b       
);

//--------------------------------------
int             fp;
string          str; //字符串类型
string          cmd_name, cmd_param; //字符串类型
logic   [7:0]   param_a;
logic   [7:0]   param_b;
logic   [7:0]   cc;
int             have_param;
int             ii;

//-----------------------------------------------------
initial 
begin
	fp = $fopen("cmd.txt", "r"); //打开控制脚本

	while($fgets(str, fp)) //获取脚本中每一行的字符串
	begin
		cc = str.getc(0); //从str中获取第一个字符
		ii = 0;
		have_param = 0;
		cmd_name  = "";
		cmd_param = "";

		while (cc != 0) //判断该字符不是空字符，0代表空字符
		begin
			//命令名称和参数用空格分开，前面是名称，后面是参数
			if (cc == " ") 
			begin
				//获得名称
				$sscanf(str.substr(0,ii-1),"%s",cmd_name);
				//获得参数，包括ii+1及后续字符
				cmd_param = str.substr(ii+1); 
				have_param = 1; //表示该命令包含参数
				break;  //跳出while循环
			end 
			else //没有遇到分隔的空格时，就一直找寻
			begin
				ii++;
				cc = str.getc(ii);
			end
		end

		if (have_param == 0) //若没有参数，说明整行语句就是命令本身
		begin
			$sscanf(str, "%s", cmd_name);
			cmd_param = "";
		end

		case(cmd_name)  //命令列表
			"AAA": 
			begin
				//提取参数
				$sscanf(cmd_param, "%d %d",param_a, param_b); 
				//执行相关task
				task_aaa(param_a, param_b);
			end

			"BBB": 
			begin
				//提取参数
				$sscanf(cmd_param, "%d", param_a);
				task_bbb(param_a);  //执行相关task
			end

			"WAIT":
			begin
				//提取参数
				$sscanf(cmd_param, "%d", param_a);
				#(param_a); //执行
			end

			"DONE":
			begin
				$finish; //没有参数，直接执行
			end
		endcase
	end
end

initial //信号初始化
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

