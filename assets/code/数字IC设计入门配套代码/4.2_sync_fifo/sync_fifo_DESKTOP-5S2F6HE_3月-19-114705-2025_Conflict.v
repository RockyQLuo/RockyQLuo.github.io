module sync_fifo
#(
	parameter  DEEPWID = 3  ,
	parameter  DEEP    = 8  ,
	parameter  BITWID  = 5     
)
(
	input                       clk                 ,
	input                       rst_n               ,

	input                       wr                  ,
	input                       rd                  ,
	input       [BITWID-1:0]    wr_dat              ,
	output  reg [BITWID-1:0]    rd_dat              , 
	output  reg                 rd_dat_vld          ,

	input       [DEEPWID-1:0]   cfg_almost_full     ,
	input       [DEEPWID-1:0]   cfg_almost_empty    ,
	output                      almost_full         ,
	output                      almost_empty        ,
	output                      full                ,
	output                      empty               ,
	output      [DEEPWID:0]     fifo_num                
);

//*****************************************************************
wire    [DEEPWID-1:0]           ram_wr_ptr          ;
wire    [DEEPWID-1:0]           ram_rd_ptr          ;
reg     [DEEPWID:0]             ram_wr_ptr_exp      ;
reg     [DEEPWID:0]             ram_rd_ptr_exp      ;
reg     [BITWID-1:0]            my_memory[DEEP-1:0] ;
integer                         ii                  ;

//****************************************************************
//���洢����д��ַ������չ��д��ַram_wr_ptr_exp��ȡ����λ
assign ram_wr_ptr = ram_wr_ptr_exp[DEEPWID-1:0];

//��չ��д��ַ��ÿ����һ��д�ͼ�1����������������DEEP-1ʱ����ص����ַ
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		ram_wr_ptr_exp <= {(DEEPWID+1){1'b0}};
	else if(wr)
	begin
		if (ram_wr_ptr_exp < DEEP + DEEP - 1)
			ram_wr_ptr_exp <= ram_wr_ptr_exp + 1;
		else
			ram_wr_ptr_exp <= {(DEEPWID+1){1'b0}};
	end
end

//���洢���Ķ���ַ������չ�Ķ���ַram_rd_ptr_exp��ȡ����λ
assign ram_rd_ptr  = ram_rd_ptr_exp[DEEPWID-1:0];

//��չ�Ķ���ַ��ÿ����һ�ζ��ͼ�1����������������DEEP-1ʱ����ص����ַ
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		ram_rd_ptr_exp <= {(DEEPWID+1){1'b0}};
	else if(rd)
	begin
		if (ram_rd_ptr_exp < DEEP + DEEP - 1)
			ram_rd_ptr_exp <= ram_rd_ptr_exp + 1;
		else
			ram_rd_ptr_exp <= {(DEEPWID+1){1'b0}};
	end
end

//����״̬�źŵ��߼�
assign fifo_num = ram_wr_ptr_exp - ram_rd_ptr_exp;

assign full = (fifo_num == DEEP) | ((fifo_num == DEEP - 1) & wr & (~rd));
assign empty = (fifo_num == 0) | ((fifo_num == 1) & rd & (~wr));
assign almost_full =   (fifo_num >= cfg_almost_full)  
			| ((fifo_num == cfg_almost_full - 1) & wr & (~rd));
assign almost_empty =  (fifo_num <= cfg_almost_empty) 
			| ((fifo_num == cfg_almost_empty + 1) & rd & (~wr));

//�üĴ����䵱FIFO�ڲ��Ĵ洢����
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n) 
		for (ii=0;ii<DEEP;ii=ii+1)
			my_memory[ii] <= {(BITWID){1'b0}};
	else
	begin
		for (ii=0; ii<DEEP; ii=ii+1)
		begin
			if(wr & (ram_wr_ptr == ii))
				my_memory[ii] <= wr_dat;
		end
	end 
end

//���ڼĴ����ٶȿ죬�����������ʵ����ֻ������߼������������
//���ﻹ�Ǹ�������һ�������
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n) 
		rd_dat <=  {BITWID{1'b0}};
	else
	begin
		if(rd)
		begin
			for (ii=0; ii<DEEP; ii=ii+1)
			begin
				if (ram_rd_ptr == ii)
					rd_dat <=  my_memory[ii];
			end
		end
	end
end

//����rd_dat��vld�źţ�Ҳ�ڶ��������һ�����
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n) 
		rd_dat_vld <= 1'b0;
	else
		rd_dat_vld <= rd;
end

endmodule

