module i2c_host
(
	output  logic   scl    ,
	inout           sda         
);


//---------- 定义I2C时间参数，单位是ns，其速率为100KHz -------------
localparam CLK_HIGH         = 5e3   ;   //scl high level time
localparam CLK_LOW          = 5e3   ;   //scl low level time

localparam START_HOLD_TIME  = 2.5e3 ;   //hold  time for start    
localparam STOP_SETUP_TIME  = 2.5e3 ;   //setup time for stop    

localparam DAT_SETUP_TIME   = 2.5e3 ;   //setup time for data
localparam DAT_HOLD_TIME    = 2.5e3 ;   //hold  time for data

localparam INTERVAL_TIME    = 5e3   ;   //wait time between stop and another start

localparam REAL_CLK_LOW = (CLK_LOW >= (DAT_SETUP_TIME + DAT_HOLD_TIME))? CLK_LOW : (DAT_SETUP_TIME + DAT_HOLD_TIME);


//-------------- 信号声明 ------------------------
logic           sda_out ;
wire            sda_in  ;
logic           sdo_en  ;
logic   [7:0]   rdat    ;


//----------- 将SDA设为双向引脚 ------------
assign sda    = sdo_en? sda_out: 1'bz; //与FPGA相同的双向引脚表述
assign sda_in = sda;


//------------ 调用task的主流程 ------------------------
initial
begin
	scl      = 1;
	sda_out  = 1;
	sdo_en   = 1;

	#100e3;
	host_wr_one_byt(8'h7, 8'h21); //发出写操作，对0x7地址写数据0x21
	#100e3;
	host_rd_one_byt(8'h7, rdat);  //发出读操作，从0x7地址读输入，存入rdat
	$display("read dat from slave: %x.", rdat); //打印，看是否读出为0x21
end


//-------------- 两个父task --------------------------
//该task负责向I2C从设备写一个字节
task host_wr_one_byt;
	input   [7:0]   addr;
	input   [7:0]   dat ;

	logic           ack ;

	start;            //发起start
	snd_byt(8'h3c);   //写chip id为0x3c，写操作
	rcv_bit(ack);     //接收ACK，但这里未用于判断，直接丢弃
	snd_byt_with_feedback(addr, ack); //发出地址，收到的ACK丢弃
	snd_byt_with_feedback(dat , ack); //发出数据，收到的ACK丢弃
	stop;             //发起stop
endtask


//该task负责从I2C的从设备中读取一个字节
//任意地址读取，先发出地址，再重新start后读取
task host_rd_one_byt;
	input           [7:0]   addr    ;
	output  logic   [7:0]   rdat    ;

	logic                   ack;

	start;           //发起start
	snd_byt(8'h3c);  //写chip id为0x3c，写操作
	rcv_bit(ack);    //接收ACK，但这里未用于判断，直接丢弃
	snd_byt_with_feedback(addr,ack); //发出地址，收到的ACK丢弃
	snd_bit(1);      //发出单比特1，使时钟SCL持续为高
	start;           //重新发起start
	snd_byt(8'h3d);  //写chip id为0x3c，但改为读操作，即0x3d
	rcv_bit(ack);    //接收ACK，但这里未用于判断，直接丢弃
	rcv_byt_then_answer(rdat, 1'h1);//接收单字节，然后返回NAK
	stop;            //发起stop
endtask


//-------------- 被父task调用的若干子task -----------------
//发出start波形
task start;
	sda_out  = 0;
	sdo_en = 1;
	#(START_HOLD_TIME);
endtask

//发出stop波形
task stop;
	snd_bit(0);
	sda_out  = 1;
	sdo_en = 1;
	#(INTERVAL_TIME);
endtask

//用于发出一个比特
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

//用于发出整个字节
task snd_byt;
	input   [7:0]   byt_dat;

	logic   [7:0]   byt_inner; //内部信号全部声明为logic或reg

	byt_inner = byt_dat;

	repeat(8) //repeat是for循环的简化表达，这里重复8次
	begin
		snd_bit(byt_inner[7]); //调用其他task 
		byt_inner = {byt_inner[6:0], 1'b1};
	end
endtask

//不仅发出整个字节，还会接收ACK
task snd_byt_with_feedback;
	input           [7:0]   byt_dat;
	output  logic           ack    ;

	snd_byt(byt_dat); //调用其他task
	rcv_bit(ack);     //调用其他task
endtask

//用于接收一个比特
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

//用于接收一个字节，并回复ACK或NAK
task rcv_byt_then_answer;
	output  [7:0]   dout;
	input           ack ;

	logic           tmp ;
	int             ii  ; //int相当于reg signed [31:0]

	for(ii=0; ii<8; ii++) 
	begin
		rcv_bit(tmp); //调用其他task
		dout = {dout[6:0],tmp};
	end

	snd_bit(ack);  //调用其他task
endtask

endmodule

