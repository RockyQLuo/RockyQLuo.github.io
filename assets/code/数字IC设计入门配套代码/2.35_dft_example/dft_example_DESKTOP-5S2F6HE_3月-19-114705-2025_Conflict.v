module dft_example 
(
	//Pad
	inout           SCAN_MODE,      //scan_modeר��Pad��ע��Pad����inout����
	inout           GPIO0,          //GPIO0 Pad��ע��Pad����inout����
	inout           GPIO1,          //GPIO1 Pad��ע��Pad����inout����
	inout           GPIO2,          //GPIO2 Pad��ע��Pad����inout����
	inout           GPIO3,          //GPIO3 Pad��ע��Pad����inout����
	inout           GPIO4,          //GPIO4 Pad��ע��Pad����inout����
	inout           GPIO5,          //GPIO5 Pad��ע��Pad����inout����
	inout           GPIO6,          //GPIO6 Pad��ע��Pad����inout����

	//оƬ�ڲ��ӿ��źţ���Pad
	input           clk  ,          //ģ��������ṩ��ʱ���ź�
	input           rst_n,          //ģ��������ṩ�ĸ�λ�ź�

	//cfg
	input           a2d_pin0,       //ģ��������ṩ����ͨ�ź�0
	input           a2d_pin1,       //ģ��������ṩ����ͨ�ź�1
	output          d2a_pin0,       //���ָ�ģ���ṩ�������ź�0
	output          d2a_pin1        //���ָ�ģ���ṩ�������ź�1
);

//------------------------------------------------------------------
wire	[1:0]	scan_do;		    //Scan������оƬ�ڲ���Ӧ���2����
wire	[1:0]	scan_do_buf;	    //scan_do����Buffer������
wire	[1:0]	scan_di;		    //Scan����������Ĳ�������2����
wire			scan_mode;		    //Pad SCAN_MODE�������ź�
wire			scan_se;		    //Scan���̵�ʹ���ź�

wire	[6:0]	pin;	            //7��GPIO��������������ź�
wire	[6:0]	pout;	            //7��GPIO��������������ź�
wire	[6:0]	p_oe;	            //7��GPIO�����������л��ź�

wire	[4:0]	pin_MUX;	        //5��GPIO���������ź�
wire			pout5_MUX;	        //2��GPIO��������źţ�GPIO5��GPIO6
wire			pout6_MUX; 

wire		    clk_changed;		//������������clkʱ�����¼Ĵ�����ʱ��
wire		    clk_changed_gated;	//clk_change��ʱ���ſ����
wire		    clk_div;			//clk�ķ�Ƶʱ���ź�
wire		    clk_div_changed;	//������������clk_divʱ�����¼Ĵ�����ʱ��
wire		    rst_n2;				//���мĴ��������ո�λ�ź�
wire		    clk_en;				//ʱ���ſ��ź�

wire	[11:0]	bus;                //cpu���߼�ģ��

wire		    a2d_pin0_changed;   //Ϊ��ӦDFT������ı��a2d_pin0
wire		    a2d_pin1_changed;   //Ϊ��ӦDFT������ı��a2d_pin1

wire		    d2a_pin0_pre;       //�Ѳ�������δ�����d2a_pin0������
wire		    d2a_pin1_pre;       //�Ѳ�������δ�����d2a_pin1������

//-----------------------------------------------------
//����SCAN_MODE Pad
pad     u_scan_mode     
(
	.PAD    (SCAN_MODE   ), //Pad���ӵ�
	.OUT    (1'b0        ), //��Padֻ�����빦�ܣ����ֵ��������д
	.OE     (1'b0        ), //Pad������Ϊ���룬�������ʹ��
	.IN     (scan_mode   )  //������ź�����Ϊscan_mode
);

//������Scanʱ��scan_se��ֵ��Դ��GPIO0������źţ�����������ʱ��scan_seΪ0
//��scan_se�źŷ�Ϊ��֧��һ֧ͨ��CPU�У���һ֧���գ��ȴ�DFT�ۺϽ������
assign scan_se = scan_mode ? pin_MUX[0] : 1'b0;

//������Scanʱ��GPIO0��scan_se��ʱ������������pin[0]���ϵ�����ֹ�䷢������
//��ˣ�������scan_mode�µ�pin[0]��0��Ҳ���Ը�Ϊ�����
//��������ʱ��pin[0]���õ�GPIO0������ֵ
assign pin[0]  = scan_mode ? 1'b0 : pin_MUX[0];

//������Scanʱ��GPIO0��scan_se�ã����Ǵ������źţ�����̶�ѡ��0��������
//����������ʱ�����Ը���GPIOģ�����������������
assign p_oe[0] = scan_mode ? 1'b0 : pout_en[0];

//pin_MUX[1]����scan_clk������GPIO1������
//������Scanʱ��ϵͳʱ��clk����GPIO1����ʱ����ȡ������������ʱ��ʹ��ϵͳʱ��clk
assign clk_changed = scan_mode ? pin_MUX[1] : clk;

//������Scanʱ��GPIO1��scan_clk�ã����pin[1]����0
//��������ʱ��pin[1]���õ�GPIO1������ֵ
assign pin[1] = scan_mode ? 1'b0 : pin_MUX[1];

//������Scanʱ��GPIO1��scan_clk�ã����Ǵ������źţ�����̶�ѡ��0��������
//����������ʱ�����Ը���GPIOģ�����������������
assign p_oe[1] = scan_mode ? 1'b0 : pout_en[1];

//��RTL�з����õ���Ƶʱ�ӵļĴ�����������ʱ������������ʱ��Ȼ��clk_div
//�ڽ���Scanʱ������ʱ�Ӹĳ�����GPIO1��ʱ��
assign clk_div_changed = scan_mode ? pin_MUX[1] : clk_div;

//rst_n2�ǼĴ����ĸ�λ�źš�������Scanʱ����λ�ź�����GPIO2������
//��������ʱ����λ�ź�����ϵͳ��λrst_n��
assign rst_n2 = scan_mode ? pin_MUX[2] : rst_n;

//������Scanʱ��GPIO2��scan_rstn�ã����pin[2]��Ϊ0
//��������ʱ��pin[2]���õ�GPIO2������ֵ
assign pin[2] = scan_mode ? 1'b0 : pin_MUX[2];

//������Scanʱ��GPIO2��scan_rstn�ã����Ǵ������źţ���˹̶�ѡ��0��������
//����������ʱ�����Ը���GPIOģ�����������������
assign p_oe[2] = scan_mode ? 1'b0 : pout_en[2];

//������Scan�����������룬�ֱ��GPIO3��GPIO4�����������������ʱ��Ϊ0
//scan_di[0]��scan_di[1]�����źž��ս�
assign scan_di[0] = scan_mode ? pin_MUX[3] : 1'b0;
assign scan_di[1] = scan_mode ? pin_MUX[4] : 1'b0;

assign pin[3] = scan_mode ? 1'b0 : pin_MUX[3];
assign pin[4] = scan_mode ? 1'b0 : pin_MUX[4];

//Scanʱ����������
assign p_oe[3] = scan_mode ? 1'b0 : pout_en[3];
assign p_oe[4] = scan_mode ? 1'b0 : pout_en[4];

//����Buffer����ֹscan_do[0]���Ż���������Լ��ʱ��λ�����ź�
//����������ġ�_abc����Ϊ���
BUF     u_scan_do_0_abc 
(
	.IN     (scan_do[0]		)	,	//Buffer����
	.OUT    (scan_do_buf[0]	)		//Buffer���
);

//����Buffer����ֹscan_do[1]���Ż���������Լ��ʱ��λ�����ź�
//����������ġ�_abc����Ϊ���
//scan_do[0]��scan_do[1]�źž�Ϊ�ս�
BUF     u_scan_do_1_abc
(
	.IN     (scan_do[1]		)	,	//Buffer����
	.OUT    (scan_do_buf[1]	)		//Buffer���
);

//GPIO5���յ������������Scanʱ�������scan_do[0]����������ʱ�������������
assign pout5_MUX = scan_mode ? scan_do_buf[0] : pout[5];

//GPIO5������ֵ��ֱ����Pad����������˿�����
assign pin[5] = pin_MUX[5];

//GPIO5��Scanʱ��Ϊscan_do[0]�����Ǵ��������˹̶�ѡ��1�������
//����������ʱ�����Ը���GPIOģ�����������������
assign p_oe[5] = scan_mode ? 1'b1 : pout_en[5];

//GPIO6���յ������������Scanʱ�������scan_do[1]����������ʱ�������������
assign pout6_MUX = scan_mode ? scan_do_buf[1] : pout[6];

assign pin[6]   = pin_MUX[6];
assign p_oe[6]  = scan_mode ? 1'b1 : pout_en[6];

//-------------------------------------------------------
//����GPIO0 Pad
pad      u_P0 
(
	.PAD    (GPIO0  ),  //Pad���ӵ�
	.OUT    (pout[0]),  //Pad���
	.OE     (p_oe[0]),  //Pad���ʹ�ܣ���I/O����
	.IN     (pin_MUX[0]) //Pad����
);

//����GPIO1 Pad
pad      u_P1 
(
	.PAD    (GPIO1), //io
	.OUT    (pout[1]), //i
	.OE     (p_oe[1]), //i
	.IN     (pin_MUX[1]) //o
);

//����GPIO2 Pad
pad      u_P2 
(
	.PAD    (GPIO2), //io
	.OUT    (pout[2]), //i
	.OE     (p_oe[2]), //i
	.IN     (pin_MUX[2]) //o
);

//����GPIO3 Pad
pad      u_P3 
(
	.PAD    (GPIO3), //io 
	.OUT    (pout[3]	), //i  
	.OE     (p_oe[3]	), //i  
	.IN     (pin_MUX[3]) //o
);

//����GPIO4 Pad
pad      u_P4 
(
	.PAD    (GPIO4), //io 
	.OUT    (pout[4]	), //i  
	.OE     (p_oe[4]	), //i  
	.IN     (pin_MUX[4]) //o
);

//����GPIO5 Pad
pad      u_P5 
(
	.PAD    (GPIO5), //io 
	.OUT    (pout5_MUX), //i
	.OE     (p_oe[5]), //i  
	.IN     (pin_MUX[5]) //o
);

//����GPIO6 Pad
pad      u_P6 
(
	.PAD    (GPIO6), //io 
	.OUT    (pout6_MUX), //i  
	.OE     (p_oe[6]), //i
	.IN     (pin_MUX[6]) //o
);

//����һ��ʱ���ſص�·
//������˵��������ʱ���ſ�������һ��Ҳ��Ҫscan_mode����
clk_gate    u_clk_gate
(
	.clk			(clk_changed		), //Դʱ����MUX�����ʱ��
	.enable			(clk_en				), //ʱ��ʹ���ź�������ģ�������
	.test_en		(scan_mode			), //��Ҫscan_mode����
	.gated_clk		(clk_changed_gated	)  //ʱ���ſص����
);

//����һ��ʱ�ӷ�Ƶ��
//������˵�������ڴ���Ƶʱ�ӵ���ƣ���Scanʱ��Ȼ��δ��Ƶʱ��һ��ʹ��scan_clk
//���ɽ�scan_clk���뵽ʱ��Դ�н��з�Ƶ��ʹ��
clk_divider     u_clk_divider
(
	.clk		(clk		), //ʱ��Դ��������scan_clk��clk_changed
	.clk_div	(clk_div	)  //��Ƶʱ�ӣ���Scanʱ��������scan_clk����
);

//����һ��CPU����DFT��Ƶ�һ�㶼��SoCоƬ
//����CPU��оƬ������SoCоƬ�����ȽϵͶˣ���ʱ����DFT
//CPU������ʱҲ��Ҫ����scan_se��scan_mode
cpu     u_cpu
(
	.clk         (clk_changed_gated), //ʱ��Դ���ں���scan_clk
	.rst_n       (rst_n2), //��λ�ź����ں���scan_rstn
	.bus         (bus), //CPU���߸���ģ��
	.scan_se     (scan_se), //i
	.scan_mode   (scan_mode) //i
);

//����-��7���������GPIOģ�飬�������CPU��������
gpio    u_gpio  
(
	.clk        (clk_changed_gated), //ʱ��Դ���ں���scan_clk
	.rst_n      (rst_n2), //��λ�ź����ں���scan_rstn
	.bus        (bus), //�ҵ�CPU������

	.pin        (pin), //��Pad�������7·GPIO�ź�
	.pout       (pout), //�������Pad��7·GPIO�ź�
	.p_oe       (p_oe) //7��GPIO Pad����������������
);

//����һ������ģ�飬�������������ڲ���ģ���·�ȣ�Ҳ���ڳ���ģ���������ͨ�ź�
cfg     u_cfg
(
	.clk         (clk_div_changed), //�õ��Ƿ�Ƶʱ��Դ������scanʱ����Ƶ
	.rst_n       (rst_n2), //��λ�ź����ں���scan_rstn
	.bus         (bus), //�ҵ�CPU������
	.a2d_pin0    (a2d_pin0_changed), //ģ���������·��ͨ�ź�
	.a2d_pin1    (a2d_pin1_changed), //changed��Ϊ��Scanʱ�������ѱ�
	.d2a_pin0    (d2a_pin0_pre), //�����ģ���·������
	.d2a_pin1    (d2a_pin1_pre), //��Scanʱ�����������������ֱ�����
	.clk_en      (clk_en) //����������ſؿ���
)

//�������ֵ���������������Scan���оƬ�ڲ���������ʹ����������źŽ��������
//��������ʱ����ԭ�ź�ֱ������
assign a2d_pin0_changed = scan_mode ? d2a_pin0_pre : a2d_pin0;
assign a2d_pin1_changed = scan_mode ? d2a_pin1_pre : a2d_pin1;

//��ģ������ù�ϵ��оƬ�ĵ�����ѹ����Ҫ������������Scan���̣�ҲҪ��֤оƬ�Ĺ�������
//��˲��������������ǽ������Щ��ʹģ������������ֵ
//�ڷ�Scanģʽ�£�����ԭ�ź�ֱ��
assign d2a_pin0 = scan_mode ? 1'b1 : d2a_pin0_pre;
assign d2a_pin1 = scan_mode ? 1'b1 : d2a_pin1_pre;

endmodule

