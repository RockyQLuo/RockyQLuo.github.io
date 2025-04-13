module dft_example 
(
	//Pad
	inout           SCAN_MODE,      //scan_mode专用Pad，注意Pad都是inout类型
	inout           GPIO0,          //GPIO0 Pad，注意Pad都是inout类型
	inout           GPIO1,          //GPIO1 Pad，注意Pad都是inout类型
	inout           GPIO2,          //GPIO2 Pad，注意Pad都是inout类型
	inout           GPIO3,          //GPIO3 Pad，注意Pad都是inout类型
	inout           GPIO4,          //GPIO4 Pad，注意Pad都是inout类型
	inout           GPIO5,          //GPIO5 Pad，注意Pad都是inout类型
	inout           GPIO6,          //GPIO6 Pad，注意Pad都是inout类型

	//芯片内部接口信号，非Pad
	input           clk  ,          //模拟给数字提供的时钟信号
	input           rst_n,          //模拟给数字提供的复位信号

	//cfg
	input           a2d_pin0,       //模拟给数字提供的普通信号0
	input           a2d_pin1,       //模拟给数字提供的普通信号1
	output          d2a_pin0,       //数字给模拟提供的配置信号0
	output          d2a_pin1        //数字给模拟提供的配置信号1
);

//------------------------------------------------------------------
wire	[1:0]	scan_do;		    //Scan过程中芯片内部响应输出2比特
wire	[1:0]	scan_do_buf;	    //scan_do经过Buffer后的输出
wire	[1:0]	scan_di;		    //Scan过程中输入的测试向量2比特
wire			scan_mode;		    //Pad SCAN_MODE的输入信号
wire			scan_se;		    //Scan过程的使能信号

wire	[6:0]	pin;	            //7个GPIO输入的正常工作信号
wire	[6:0]	pout;	            //7个GPIO输出的正常工作信号
wire	[6:0]	p_oe;	            //7个GPIO输入和输出的切换信号

wire	[4:0]	pin_MUX;	        //5根GPIO复用输入信号
wire			pout5_MUX;	        //2根GPIO复用输出信号，GPIO5和GPIO6
wire			pout6_MUX; 

wire		    clk_changed;		//最终用于驱动clk时钟域下寄存器的时钟
wire		    clk_changed_gated;	//clk_change的时钟门控输出
wire		    clk_div;			//clk的分频时钟信号
wire		    clk_div_changed;	//最终用于驱动clk_div时钟域下寄存器的时钟
wire		    rst_n2;				//所有寄存器的最终复位信号
wire		    clk_en;				//时钟门控信号

wire	[11:0]	bus;                //cpu总线简化模型

wire		    a2d_pin0_changed;   //为适应DFT需求而改变的a2d_pin0
wire		    a2d_pin1_changed;   //为适应DFT需求而改变的a2d_pin1

wire		    d2a_pin0_pre;       //已产生但尚未输出的d2a_pin0配置字
wire		    d2a_pin1_pre;       //已产生但尚未输出的d2a_pin1配置字

//-----------------------------------------------------
//例化SCAN_MODE Pad
pad     u_scan_mode     
(
	.PAD    (SCAN_MODE   ), //Pad连接点
	.OUT    (1'b0        ), //该Pad只用输入功能，输出值可任意填写
	.OE     (1'b0        ), //Pad方向设为输入，即输出不使能
	.IN     (scan_mode   )  //输入的信号命名为scan_mode
);

//当进行Scan时，scan_se的值来源于GPIO0输入的信号，当正常工作时，scan_se为0
//该scan_se信号分为两支，一支通入CPU中，另一支悬空，等待DFT综合将其接入
assign scan_se = scan_mode ? pin_MUX[0] : 1'b0;

//当进行Scan时，GPIO0当scan_se用时，正常的输入pin[0]被断掉，阻止其发挥作用
//因此，本例给scan_mode下的pin[0]赋0，也可以赋为随机数
//正常工作时，pin[0]将得到GPIO0的输入值
assign pin[0]  = scan_mode ? 1'b0 : pin_MUX[0];

//当进行Scan时，GPIO0当scan_se用，它是纯输入信号，因而固定选择0，即输入
//当正常工作时，可以根据GPIO模块的设置来决定方向
assign p_oe[0] = scan_mode ? 1'b0 : pout_en[0];

//pin_MUX[1]就是scan_clk，它是GPIO1的输入
//当进行Scan时，系统时钟clk被从GPIO1来的时钟所取代，正常工作时仍使用系统时钟clk
assign clk_changed = scan_mode ? pin_MUX[1] : clk;

//当进行Scan时，GPIO1当scan_clk用，因此pin[1]被赋0
//正常工作时，pin[1]将得到GPIO1的输入值
assign pin[1] = scan_mode ? 1'b0 : pin_MUX[1];

//当进行Scan时，GPIO1当scan_clk用，它是纯输入信号，因而固定选择0，即输入
//当正常工作时，可以根据GPIO模块的设置来决定方向
assign p_oe[1] = scan_mode ? 1'b0 : pout_en[1];

//在RTL中凡是用到分频时钟的寄存器，其驱动时钟在正常工作时仍然是clk_div
//在进行Scan时，驱动时钟改成来自GPIO1的时钟
assign clk_div_changed = scan_mode ? pin_MUX[1] : clk_div;

//rst_n2是寄存器的复位信号。当进行Scan时，复位信号来自GPIO2的输入
//正常工作时，复位信号来自系统复位rst_n。
assign rst_n2 = scan_mode ? pin_MUX[2] : rst_n;

//当进行Scan时，GPIO2当scan_rstn用，因此pin[2]设为0
//正常工作时，pin[2]将得到GPIO2的输入值
assign pin[2] = scan_mode ? 1'b0 : pin_MUX[2];

//当进行Scan时，GPIO2当scan_rstn用，它是纯输入信号，因此固定选择0，即输入
//当正常工作时，可以根据GPIO模块的设置来决定方向
assign p_oe[2] = scan_mode ? 1'b0 : pout_en[2];

//两比特Scan测试向量输入，分别从GPIO3和GPIO4输入进来，正常工作时均为0
//scan_di[0]和scan_di[1]两根信号均空接
assign scan_di[0] = scan_mode ? pin_MUX[3] : 1'b0;
assign scan_di[1] = scan_mode ? pin_MUX[4] : 1'b0;

assign pin[3] = scan_mode ? 1'b0 : pin_MUX[3];
assign pin[4] = scan_mode ? 1'b0 : pin_MUX[4];

//Scan时，都是输入
assign p_oe[3] = scan_mode ? 1'b0 : pout_en[3];
assign p_oe[4] = scan_mode ? 1'b0 : pout_en[4];

//例化Buffer，防止scan_do[0]被优化，方便在约束时定位到该信号
//名称用特殊的“_abc”作为标记
BUF     u_scan_do_0_abc 
(
	.IN     (scan_do[0]		)	,	//Buffer输入
	.OUT    (scan_do_buf[0]	)		//Buffer输出
);

//例化Buffer，防止scan_do[1]被优化，方便在约束时定位到该信号
//名称用特殊的“_abc”作为标记
//scan_do[0]和scan_do[1]信号均为空接
BUF     u_scan_do_1_abc
(
	.IN     (scan_do[1]		)	,	//Buffer输入
	.OUT    (scan_do_buf[1]	)		//Buffer输出
);

//GPIO5最终的输出，当进行Scan时输出的是scan_do[0]，正常工作时输出正常的数据
assign pout5_MUX = scan_mode ? scan_do_buf[0] : pout[5];

//GPIO5的输入值，直接与Pad的数据输入端口相连
assign pin[5] = pin_MUX[5];

//GPIO5在Scan时作为scan_do[0]，它是纯输出，因此固定选择1，即输出
//当正常工作时，可以根据GPIO模块的设置来决定方向
assign p_oe[5] = scan_mode ? 1'b1 : pout_en[5];

//GPIO6最终的输出，当进行Scan时输出的是scan_do[1]，正常工作时输出正常的数据
assign pout6_MUX = scan_mode ? scan_do_buf[1] : pout[6];

assign pin[6]   = pin_MUX[6];
assign p_oe[6]  = scan_mode ? 1'b1 : pout_en[6];

//-------------------------------------------------------
//例化GPIO0 Pad
pad      u_P0 
(
	.PAD    (GPIO0  ),  //Pad连接点
	.OUT    (pout[0]),  //Pad输出
	.OE     (p_oe[0]),  //Pad输出使能，即I/O方向
	.IN     (pin_MUX[0]) //Pad输入
);

//例化GPIO1 Pad
pad      u_P1 
(
	.PAD    (GPIO1), //io
	.OUT    (pout[1]), //i
	.OE     (p_oe[1]), //i
	.IN     (pin_MUX[1]) //o
);

//例化GPIO2 Pad
pad      u_P2 
(
	.PAD    (GPIO2), //io
	.OUT    (pout[2]), //i
	.OE     (p_oe[2]), //i
	.IN     (pin_MUX[2]) //o
);

//例化GPIO3 Pad
pad      u_P3 
(
	.PAD    (GPIO3), //io 
	.OUT    (pout[3]	), //i  
	.OE     (p_oe[3]	), //i  
	.IN     (pin_MUX[3]) //o
);

//例化GPIO4 Pad
pad      u_P4 
(
	.PAD    (GPIO4), //io 
	.OUT    (pout[4]	), //i  
	.OE     (p_oe[4]	), //i  
	.IN     (pin_MUX[4]) //o
);

//例化GPIO5 Pad
pad      u_P5 
(
	.PAD    (GPIO5), //io 
	.OUT    (pout5_MUX), //i
	.OE     (p_oe[5]), //i  
	.IN     (pin_MUX[5]) //o
);

//例化GPIO6 Pad
pad      u_P6 
(
	.PAD    (GPIO6), //io 
	.OUT    (pout6_MUX), //i  
	.OE     (p_oe[6]), //i
	.IN     (pin_MUX[6]) //o
);

//例化一个时钟门控电路
//此例想说明：对于时钟门控器件，一般也需要scan_mode输入
clk_gate    u_clk_gate
(
	.clk			(clk_changed		), //源时钟是MUX后的总时钟
	.enable			(clk_en				), //时钟使能信号是配置模块产生的
	.test_en		(scan_mode			), //需要scan_mode输入
	.gated_clk		(clk_changed_gated	)  //时钟门控的输出
);

//例化一个时钟分频器
//此例想说明：对于带分频时钟的设计，在Scan时仍然和未分频时钟一样使用scan_clk
//不可将scan_clk输入到时钟源中进行分频再使用
clk_divider     u_clk_divider
(
	.clk		(clk		), //时钟源，不能用scan_clk或clk_changed
	.clk_div	(clk_div	)  //分频时钟，在Scan时，它将被scan_clk代替
);

//例化一个CPU。做DFT设计的一般都是SoC芯片
//不带CPU的芯片，即非SoC芯片往往比较低端，有时不做DFT
//CPU本身有时也需要输入scan_se和scan_mode
cpu     u_cpu
(
	.clk         (clk_changed_gated), //时钟源已融合了scan_clk
	.rst_n       (rst_n2), //复位信号已融合了scan_rstn
	.bus         (bus), //CPU总线概念模型
	.scan_se     (scan_se), //i
	.scan_mode   (scan_mode) //i
);

//例化-个7输入输出的GPIO模块，将其挂在CPU的总线上
gpio    u_gpio  
(
	.clk        (clk_changed_gated), //时钟源已融合了scan_clk
	.rst_n      (rst_n2), //复位信号已融合了scan_rstn
	.bus        (bus), //挂到CPU总线上

	.pin        (pin), //从Pad上输入的7路GPIO信号
	.pout       (pout), //想输出给Pad的7路GPIO信号
	.p_oe       (p_oe) //7个GPIO Pad的输入输出方向控制
);

//例化一个配置模块，用于配置数字内部、模拟电路等，也用于吃入模拟输入的普通信号
cfg     u_cfg
(
	.clk         (clk_div_changed), //用的是分频时钟源，但在scan时不分频
	.rst_n       (rst_n2), //复位信号已融合了scan_rstn
	.bus         (bus), //挂到CPU总线上
	.a2d_pin0    (a2d_pin0_changed), //模拟输入的两路普通信号
	.a2d_pin1    (a2d_pin1_changed), //changed意为在Scan时其内容已变
	.d2a_pin0    (d2a_pin0_pre), //输出给模拟电路的配置
	.d2a_pin1    (d2a_pin1_pre), //在Scan时它可能是随机数不能直接输出
	.clk_en      (clk_en) //设置上面的门控开关
)

//将输入的值随机化，更有助于Scan检查芯片内部错误，这里使用输出配置信号将其随机化
//正常工作时就与原信号直接相连
assign a2d_pin0_changed = scan_mode ? d2a_pin0_pre : a2d_pin0;
assign a2d_pin1_changed = scan_mode ? d2a_pin1_pre : a2d_pin1;

//对模拟的配置关系到芯片的电流电压等重要参数，即便是Scan过程，也要保证芯片的供电正常
//因此不能随便输出，而是仅输出那些能使模拟正常工作的值
//在非Scan模式下，就与原信号直连
assign d2a_pin0 = scan_mode ? 1'b1 : d2a_pin0_pre;
assign d2a_pin1 = scan_mode ? 1'b1 : d2a_pin1_pre;

endmodule

