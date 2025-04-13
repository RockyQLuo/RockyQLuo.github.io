`timescale 1ns/1ps

module tb;
//---------- 变量声明部分 ---------------------------
real            timeBai[$]      ;
real            timeBai2[$]     ;
real            dtime[$]        ;
real            dat_vector[$]   ;
integer         file            ;
integer         cnt             ;
integer         lineNum         ;

real            dat_f           ;
wire            dat             ;

//----------- 仿真平台主体部分 --------------------------
initial
begin
	file = $fopen("AAA.csv", "r"); //打开文件句柄

	//循环读取文件内容，直到文件结尾
	cnt     = 0;
	while (!$feof(file))
	begin
		$fscanf(file, "%f,%f", timeBai[cnt], dat_vector[cnt]);
		cnt ++;
	end
	$fclose(file); //关闭句柄
	lineNum = cnt; //保存数据量

	//转换时间单位，从s转换为ns，以符合timescale的要求
	for (cnt=0; cnt<lineNum; cnt++)
	begin
		timeBai[cnt] = timeBai[cnt] * 1e9;
	end

	// 从绝对时间timeBai中获取间隔时间dtime
	for (cnt=0; cnt<lineNum-1; cnt++)
	begin
		timeBai2[cnt] = timeBai[cnt+1];
		dtime[cnt]    = timeBai2[cnt] - timeBai[cnt];
	end
	timeBai2.delete(); //释放无用的变量
	timeBai.delete();  //释放无用的变量

	dat_f = 0; //要发出的模拟波形
	#19e6;
	for (cnt=0; cnt<lineNum-2; cnt++)
	begin
		dat_f = dat_vector[cnt];
		#(dtime[cnt]);
	end

	$finish; //发完数据后，仿真结束
end

assign dat = dat_f > 1.65; //组合逻辑：将模拟信号判决为数字信号

endmodule

