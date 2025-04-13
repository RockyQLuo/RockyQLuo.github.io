module i2c_host
(
	output  logic   scl    ,
	inout           sda         
);


//---------- ����I2Cʱ���������λ��ns��������Ϊ100KHz -------------
localparam CLK_HIGH         = 5e3   ;   //scl high level time
localparam CLK_LOW          = 5e3   ;   //scl low level time

localparam START_HOLD_TIME  = 2.5e3 ;   //hold  time for start    
localparam STOP_SETUP_TIME  = 2.5e3 ;   //setup time for stop    

localparam DAT_SETUP_TIME   = 2.5e3 ;   //setup time for data
localparam DAT_HOLD_TIME    = 2.5e3 ;   //hold  time for data

localparam INTERVAL_TIME    = 5e3   ;   //wait time between stop and another start

localparam REAL_CLK_LOW = (CLK_LOW >= (DAT_SETUP_TIME + DAT_HOLD_TIME))? CLK_LOW : (DAT_SETUP_TIME + DAT_HOLD_TIME);


//-------------- �ź����� ------------------------
logic           sda_out ;
wire            sda_in  ;
logic           sdo_en  ;
logic   [7:0]   rdat    ;


//----------- ��SDA��Ϊ˫������ ------------
assign sda    = sdo_en? sda_out: 1'bz; //��FPGA��ͬ��˫�����ű���
assign sda_in = sda;


//------------ ����task�������� ------------------------
initial
begin
	scl      = 1;
	sda_out  = 1;
	sdo_en   = 1;

	#100e3;
	host_wr_one_byt(8'h7, 8'h21); //����д��������0x7��ַд����0x21
	#100e3;
	host_rd_one_byt(8'h7, rdat);  //��������������0x7��ַ�����룬����rdat
	$display("read dat from slave: %x.", rdat); //��ӡ�����Ƿ����Ϊ0x21
end


//-------------- ������task --------------------------
//��task������I2C���豸дһ���ֽ�
task host_wr_one_byt;
	input   [7:0]   addr;
	input   [7:0]   dat ;

	logic           ack ;

	start;            //����start
	snd_byt(8'h3c);   //дchip idΪ0x3c��д����
	rcv_bit(ack);     //����ACK��������δ�����жϣ�ֱ�Ӷ���
	snd_byt_with_feedback(addr, ack); //������ַ���յ���ACK����
	snd_byt_with_feedback(dat , ack); //�������ݣ��յ���ACK����
	stop;             //����stop
endtask


//��task�����I2C�Ĵ��豸�ж�ȡһ���ֽ�
//�����ַ��ȡ���ȷ�����ַ��������start���ȡ
task host_rd_one_byt;
	input           [7:0]   addr    ;
	output  logic   [7:0]   rdat    ;

	logic                   ack;

	start;           //����start
	snd_byt(8'h3c);  //дchip idΪ0x3c��д����
	rcv_bit(ack);    //����ACK��������δ�����жϣ�ֱ�Ӷ���
	snd_byt_with_feedback(addr,ack); //������ַ���յ���ACK����
	snd_bit(1);      //����������1��ʹʱ��SCL����Ϊ��
	start;           //���·���start
	snd_byt(8'h3d);  //дchip idΪ0x3c������Ϊ����������0x3d
	rcv_bit(ack);    //����ACK��������δ�����жϣ�ֱ�Ӷ���
	rcv_byt_then_answer(rdat, 1'h1);//���յ��ֽڣ�Ȼ�󷵻�NAK
	stop;            //����stop
endtask


//-------------- ����task���õ�������task -----------------
//����start����
task start;
	sda_out  = 0;
	sdo_en = 1;
	#(START_HOLD_TIME);
endtask

//����stop����
task stop;
	snd_bit(0);
	sda_out  = 1;
	sdo_en = 1;
	#(INTERVAL_TIME);
endtask

//���ڷ���һ������
task snd_bit;
	input dat_in;

	wait(scl);
	scl = 0;
	#(DAT_HOLD_TIME);

	sda_out  = dat_in;
	sdo_en = 1;
	#(REAL_CLK_LOW - DAT_HOLD_TIME);

	scl = 1;
	#(CLK_HIGH);  
endtask

//���ڷ��������ֽ�
task snd_byt;
	input   [7:0]   byt_dat;

	logic   [7:0]   byt_inner; //�ڲ��ź�ȫ������Ϊlogic��reg

	byt_inner = byt_dat;

	repeat(8) //repeat��forѭ���ļ򻯱������ظ�8��
	begin
		snd_bit(byt_inner[7]); //��������task 
		byt_inner = {byt_inner[6:0], 1'b1};
	end
endtask

//�������������ֽڣ��������ACK
task snd_byt_with_feedback;
	input           [7:0]   byt_dat;
	output  logic           ack    ;

	snd_byt(byt_dat); //��������task
	rcv_bit(ack);     //��������task
endtask

//���ڽ���һ������
task rcv_bit;
	output      bit_valu;

	scl = 0;
	#(DAT_HOLD_TIME);

	sda_out = 1;
	sdo_en  = 0;
	#(REAL_CLK_LOW - DAT_HOLD_TIME);  

	scl         = 1     ;
	bit_valu    = sda_in;
	#(CLK_HIGH);
endtask

//���ڽ���һ���ֽڣ����ظ�ACK��NAK
task rcv_byt_then_answer;
	output  [7:0]   dout;
	input           ack ;

	logic           tmp ;
	int             ii  ; //int�൱��reg signed [31:0]

	for(ii=0; ii<8; ii++) 
	begin
		rcv_bit(tmp); //��������task
		dout = {dout[6:0],tmp};
	end

	snd_bit(ack);  //��������task
endtask

endmodule

