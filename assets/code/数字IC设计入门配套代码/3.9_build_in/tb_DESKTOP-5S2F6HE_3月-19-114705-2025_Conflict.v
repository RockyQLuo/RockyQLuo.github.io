`timescale    1ns/1ps    //精度声明

//建立TB模块，可以用其他名字，但tb或以tb为前缀的名称较为常见，读者易于辨认
//tb没有对外接口参数，所有动作都发生在tb内部，因此tb后面直接使用分号关闭
module tb;
//------------  内部变量声明    --------------------
int                 fsdbDump    ;
logic				clk			;
logic				rst_n		;

logic				trig		;

real				z			;
logic	    [16:0]	z_fix		;
wire				vld			;//不仅DUT，任何模块的输出都是wire

wire signed	[11:0]	atany		;
real				atany_real	;
real				atany_get	;

real				err_atan	;
real				max_err		;

//------------    主体内容    --------------------
initial
begin
    $fsdbDumpfile("tb.fsdb");
    $fsdbDumpvars(0);
end

//生成时钟，周期是是32MHz
initial
begin
	clk = 1'b0;
	forever
	begin
		#(1e9/(2.0*32e6)) clk = ~clk;
	end
end

//生成复位信号，它在1ms处解复位，即1e6ns处
initial
begin
	rst_n = 1'b0;
	#1e6  rst_n = 1'b1;
end

//主要的激励源模块
initial
begin
	//初始化各激励变量
	trig = 1'b0;
	z = -255;
	z_fix = 1'b0;

	//等到解复位后再等10us
	@(posedge rst_n);
	#10e3;

	//本仿真验收标准是输入-255~255，步长为1/256，对应的输出结果都正确，视为通过
	//因此，这里按要求，借助while循环，分时分步构造激励
	z = -255;
	while (z <= 255)
	begin
		//当探测到一个时钟上升沿后，就trigger一下DUT，激发DUT开始运算
		@(posedge clk); trig <= 1'b1;

		//trigger的同时，输入数据z_fix也要准备好
		//这里将z乘以256是因为z_fix是z的定点化，z的小数部分被量化为8位
		z_fix <= int'(z*256);

		//这里想将trig构造为脉冲信号，因此，再来一个时钟沿，trig就下去
		@(posedge clk); trig <= 1'b0;

		//等待计算完成，当DUT计算完成时，vld会起一个脉冲信号，方才停止
		wait(vld);

		//上次运算完成后的500ns，激励数据更新，并再等500ns
		#5e2 z = z + 1/256.0;
		#5e2;
	end

	//当全部输入任务完成，且计算也完成后，再等1us，结束仿真
	#1e3 $finish;
end

//以下是参考模型
//使用always块相当于使用initial和forever，本质相同
always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	begin
		atany_get  <= -1.56;
		atany_real <= 0;
	end
	else
	begin
		//DUT的输出结果atany是定点化后的浮点数，需要在tb中恢复为浮点数
		//恢复的浮点数，即atany_get，除以1024是因为原定点为10比特小数精度
		//atany_real是真正的对照组
		//tb中会将atany_get和atany_real进行对照
		//每当计算结果出来后，就更新一次
		if (vld)
		begin
			//这里需要强制转换为浮点数才行
			atany_get  <= real'(atany)/1024; 
			atany_real <= $atan(z); //使用内建函数算出标准答案
		end
	end
end

//计算DUT结果与参考答案的差别，并取绝对值。算法中不关心误差的符号，只关心绝对值
assign err_atan = $abs(atany_real - atany_get);

//自动寻找错误的最大值，即最大误差
always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		max_err <= 0;
	else
	begin
		//每当计算结束后，就会更新最大误差结果
		if (vld)
		begin
			//这个#1延迟很重要，如果不写的话，此刻误差还没算出来
			//必须象征性延迟一下，等待误差计算出来
			//tb不是硬件，没有计算延迟
			//因此计算是瞬间完成的，这里写#0.001也可以
			#1;
			if (err_atan > max_err)
				max_err <= err_atan;
		end
	end
end

//例化DUT
atan    u_atan
(
	.clk     (clk	),//i
	.rst_n   (rst_n	),//i

	.trig    (trig	),//i，计算触发脉冲
	.vld     (vld	),//o，计算结果有效脉冲

	.para_in (z_fix	),//i[16:0]，有符号，8位整数，8位小数
	.atany   (atany	) //i[11:0]，有符号，1位整数，10位小数
);

endmodule

