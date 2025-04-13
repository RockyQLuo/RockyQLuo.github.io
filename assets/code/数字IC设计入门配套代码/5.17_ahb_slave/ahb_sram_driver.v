module ahb_sram_driver 
(
  input                 HCLK        ,      
  input                 HRESETn     ,   
  input                 HSEL        ,      
  input                 HREADY      ,    
  input         [1:0]   HTRANS      ,    
  input         [2:0]   HSIZE       ,     
  input                 HWRITE      ,    
  input         [12:0]  HADDR       ,     
  input         [31:0]  HWDATA      ,    
  output        [31:0]  HRDATA          
);   

//----------------------------------------------
wire                    sel                 ;
wire                    wr                  ;
wire                    rd                  ;
wire                    byt0                ;
wire                    byt1                ;
wire                    byt2                ;
wire                    byt3                ;
reg                     wr_r                ;
reg                     wr_byt0_latch       ;
reg                     wr_byt1_latch       ;
reg                     wr_byt2_latch       ;
reg                     wr_byt3_latch       ;
reg             [10:0]  wr_addr_inte_latch  ;
reg                     buf_hit             ;
reg             [31:0]  wdat_latch          ;
reg                     buf_pend            ;
wire                    ram_wr              ;
reg             [31:0]  ram_wr_en_n         ;
wire                    ram_csn             ;
wire            [10:0]  ram_addr_inte       ;
wire            [31:0]  ram_wdat            ;
wire            [31:0]  ram_rdat            ;


//----------------------------------------------
//与前例相同的sel逻辑
assign sel = HSEL & HTRANS[1] & HREADY;

//总线读写操作信号
assign wr  = sel & HWRITE;
assign rd  = sel & (~HWRITE);

//比特选择逻辑不变
assign byt0= HSIZE[1] | (HSIZE[0] & (~HADDR[1])) | (HADDR[1:0]==2'b00);
assign byt1= HSIZE[1] | (HSIZE[0] & (~HADDR[1])) | (HADDR[1:0]==2'b01);
assign byt2= HSIZE[1] | (HSIZE[0] & HADDR[1])    | (HADDR[1:0]==2'b10);
assign byt3= HSIZE[1] | (HSIZE[0] & HADDR[1])    | (HADDR[1:0]==2'b11);

always @(posedge HCLK or negedge HRESETn)
begin
	if (!HRESETn)
		wr_r <= 1'b0;
	else
		wr_r <= wr;
end

//缓存写位置
always @(posedge HCLK or negedge HRESETn)
begin
	if (!HRESETn)
	begin
		wr_byt0_latch      <= 1'b0;
		wr_byt1_latch      <= 1'b0;
		wr_byt2_latch      <= 1'b0;
		wr_byt3_latch      <= 1'b0;
	end
	else if (wr)
	begin
		wr_byt0_latch   <= byt0 & sel;
		wr_byt1_latch   <= byt1 & sel;
		wr_byt2_latch   <= byt2 & sel;
		wr_byt3_latch   <= byt3 & sel;
	end
end

//缓存写地址
always @(posedge HCLK or negedge HRESETn)
begin
	if (!HRESETn)
		wr_addr_inte_latch <= 11'd0;
	else if (wr)
		wr_addr_inte_latch <= HADDR[12:2];
end

//与缓存地址进行对比，判断是否命中
always @(posedge HCLK or negedge HRESETn)
begin
	if (!HRESETn)
		buf_hit <= 1'b0;
	else if(rd)
	begin
		if (HADDR[12:2] == wr_addr_inte_latch)
			buf_hit <= 1'b1;
		else
			buf_hit <= 1'b0;
	end
end

//缓存写数据
always @(posedge HCLK or negedge HRESETn)
begin
	if (!HRESETn)
		wdat_latch <= 32'd0;
	else if (wr_r)
	begin
		if (wr_byt0_latch)
			wdat_latch[7:0]     <= HWDATA[7:0];

		if (wr_byt1_latch)
			wdat_latch[15:8]    <= HWDATA[15:8];

		if (wr_byt2_latch)
			wdat_latch[23:16]   <= HWDATA[23:16];

		if (wr_byt3_latch)
			wdat_latch[31:24]   <= HWDATA[31:24];
	end
end

//若命中，则从缓存中调用写数据直接读出，未命中，则读SRAM
assign HRDATA =
{ (buf_hit & wr_byt3_latch) ? wdat_latch[31:24] : ram_rdat[31:24],
  (buf_hit & wr_byt2_latch) ? wdat_latch[23:16] : ram_rdat[23:16],
  (buf_hit & wr_byt1_latch) ? wdat_latch[15: 8] : ram_rdat[15: 8],
  (buf_hit & wr_byt0_latch) ? wdat_latch[ 7: 0] : ram_rdat[ 7: 0] };

//--------------------------------------------------------------
//写请求挂起逻辑，若操作顺序为：写->读则写操作进入SRAM的真正时间被推迟，即挂起
always @(posedge HCLK or negedge HRESETn)
begin
	if (!HRESETn)
		buf_pend <= 1'b0;
	else
	begin
		if (~buf_pend)
		begin
			if (wr_r & rd)
				buf_pend <= 1'b1; //先写后读，挂起
			else
				buf_pend <= 1'b0; //不挂起
		end
		else //buf_pend == 1
		begin
			if (rd)
				buf_pend <= 1'b1; //保持挂起状态的方法是连续读，中间不能断
			else
				buf_pend <= 1'b0;
		end
	end
end

//挂起状态中断，或者没有发生挂起，就会发生SRAM的实际写操作
assign ram_wr = (buf_pend | wr_r) & (~rd);

//32位比特使能信号，低有效
always @(*)
begin
	if (ram_wr)
		ram_wr_en_n =  {{8{~wr_byt3_latch}},
						{8{~wr_byt2_latch}},
						{8{~wr_byt1_latch}},
						{8{~wr_byt0_latch}}};
	else
		ram_wr_en_n = 32'hffffffff;
end

//SRAM片选信号，低有效。只要SRAM发生了实际读或写，都需要拉低
assign ram_csn = ~(rd | ram_wr);

//SRAM地址，只接受32位地址，去除末尾两位
assign ram_addr_inte = rd ? HADDR[12:2] : wr_addr_inte_latch;

//SRAM写数据，若刚才是挂起的，则从缓存中取数据，若未挂起，则从总线上取数据
assign ram_wdat = buf_pend ? wdat_latch : HWDATA;

//例化SRAM
sram    u_sram
(
	.CLK        (HCLK			), //i
	.CEN        (ram_csn		), //i
	.WEN        (ram_wr_en_n	), //i[31:0]
	.A          (ram_addr_inte	), //i[10:0]
	.D          (ram_wdat		), //i[31:0]
	.Q          (ram_rdat		)  //o[31:0]
);


endmodule
