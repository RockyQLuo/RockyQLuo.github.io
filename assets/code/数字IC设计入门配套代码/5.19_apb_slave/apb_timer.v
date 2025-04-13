module apb_timer 
(
	//ref
	input                   refclk      ,
	input                   refrstn     ,

	//apb inf
	input                   PCLK        ,        
	input                   PCLKGated   ,        
	input                   PRESETn     ,       
	input                   PSEL        ,       
	input           [1:0]   PADDR       ,      
	input                   PENABLE     ,        
	input                   PWRITE      ,        
	input           [31:0]  PWDATA      ,      
	output  reg     [31:0]  PRDATA      ,      
	output                  PREADY      ,
	output                  PSLVERR     ,

	//function
	output                  int_timer              
); 

//------------------------------------------------------------
wire            rd_en               ;
wire            wr_access_en        ; 
wire            wr_en0              ; 
wire            wr_en1              ; 
wire            wr_en2              ; 
wire            int_clr             ;
wire            forc_rld            ;
reg             timer_en            ;
reg             int_en              ;
reg     [31:0]  rld_dat             ;
wire    [31:0]  rld_dat_sync2ref    ;
wire            forc_rld_sync2ref   ;   
wire            rld_en_busy         ;
wire            timer_en_sync2ref   ; 
wire            auto_rld            ;   
wire            auto_rld_sync2apb   ;   
wire            auto_rld_busy       ;
reg             cur_cnt_vld         ;
wire            cur_cnt_busy        ;
reg     [31:0]  cur_cnt             ;
wire    [31:0]  cur_cnt_sync2apb    ;  
reg             raw_int             ;


//------------------------------------------------------------
//APB接口信号解析
assign rd_en        = PSEL & (~PWRITE);             
assign wr_access_en = PSEL & (~PENABLE) & PWRITE;    
assign wr_en0       = wr_access_en & (PADDR == 2'd0);
assign wr_en1       = wr_access_en & (PADDR == 2'd1);
assign wr_en2       = wr_access_en & (PADDR == 2'd2);
assign PSLVERR      = 1'b0;

//产生只写信号
assign int_clr      = wr_en2 & PWDATA[0];
assign forc_rld     = wr_en2 & PWDATA[2];

//APB配置信号
always @(posedge PCLKGated or negedge PRESETn)
begin
	if (!PRESETn)
	begin
		timer_en    <= 1'b0;
		int_en      <= 1'b0;
	end
	else if (wr_en0)
	begin
		timer_en    <= PWDATA[0];
		int_en      <= PWDATA[1];
	end
end

always @(posedge PCLKGated or negedge PRESETn)
begin 
	if (!PRESETn)
		rld_dat <= 32'hffffffff;
	else if (wr_en1)
		rld_dat <= PWDATA;
end

//APB读信号
always @(*)
begin
	if (rd_en)
	begin
		case (PADDR)
			2'd0:   PRDATA = {30'd0, int_en, timer_en};
			2'd1:   PRDATA = rld_dat;
			2'd2:   PRDATA = {30'd0, raw_int, int_timer};
			2'd3:   PRDATA = cur_cnt_sync2apb;
			default:PRDATA = 32'd0;
		endcase
	end
	else
		PRDATA = 32'd0;
end

//当forc_rld引发rld_dat同步时，PREADY拉低
assign PREADY = ~(forc_rld | rld_en_busy);

//将rld_dat从APB域同步到工作域
sync_bus    
#(
	.BUS_WIDTH (32),
	.INIT      (32'hffffffff)
)  u_rld_sync2ref
(
	.clk1       (PCLK               ),//i
	.rstn1      (PRESETn            ),//i
	.clk2       (refclk             ),//i
	.rstn2      (refrstn            ),//i
	.bus1       (rld_dat            ),//i[31:0]
	.bus2       (rld_dat_sync2ref   ),//o[31:0]
	.sig1       (forc_rld           ),//i
	.sig2       (forc_rld_sync2ref  ),//o   
	.busy1      (rld_en_busy        ) //o
);

//将timer_en从APB域同步到工作域
sync_direct #(.BUS_WIDTH    (1))    u_en_sync2ref
(
	.clk1       (PCLK               ),//i
	.rstn1      (PRESETn            ),//i
	.clk2       (refclk             ),//i
	.rstn2      (refrstn            ),//i
	.bus1       (timer_en           ),//i
	.bus2       (timer_en_sync2ref  ) //o   
);

//计时器的核心逻辑，计数器本身，从rld_dat递减到0后会引发中断
//当forc_rld命令发起后，会打断其计数进程，重新载入初始数据
always @(posedge refclk or negedge refrstn)
begin 
	if (!refrstn)
		cur_cnt <= 32'hffffffff;
	else 
	begin
		if (forc_rld_sync2ref | auto_rld) 
			cur_cnt <= rld_dat_sync2ref;
		else if (timer_en_sync2ref)
			cur_cnt <= cur_cnt - 32'd1;
	end
end


//为反馈cur_cnt数值而产生的toggle同步驱动信号
always @(posedge refclk or negedge refrstn)
begin
	if (!refrstn)
		cur_cnt_vld <= 1'b0;
	else if (timer_en_sync2ref)
		cur_cnt_vld <= ~cur_cnt_vld;
end

//用cur_cnt_vld驱动cur_cnt，从工作域同步到APB域
sync_bus    
#(
	.BUS_WIDTH  (32),
	.INIT       (32'hffffffff)          
)   u_cur_cnt_sync2apb
(
	.clk1       (refclk                         ),//i
	.rstn1      (refrstn                        ),//i
	.clk2       (PCLK                           ),//i
	.rstn2      (PRESETn                        ),//i
	.bus1       (cur_cnt                        ),//i[31:0]
	.bus2       (cur_cnt_sync2apb               ),//o[31:0]   
	.sig1       (cur_cnt_vld & (~cur_cnt_busy)  ),//i
	.sig2       (                               ),//o
	.busy1      (cur_cnt_busy                   ) //o
);

//自动载入脉冲，能迫使cur_cnt重新载入初始值,同时也是中断产生的条件
assign auto_rld = (cur_cnt == 32'd0);

//将auto_rld从工作域同步到APB域
sync_sig    u_auto_rld
(
	.clk1        (refclk                        ),//i
	.rstn1       (refrstn                       ),//i
	.clk2        (PCLK                          ),//i
	.rstn2       (PRESETn                       ),//i
	.sig1        (auto_rld & (~auto_rld_busy)   ),//i
	.sig2        (auto_rld_sync2apb             ),//o
	.busy1       (auto_rld_busy                 ) //o     
);

//中断状态标志，是一根Latch信号，因此必须用时序逻辑
//当auto_rld时，状态为1，用户手动清零后才恢复0
always @(posedge PCLK or negedge PRESETn)
begin
	if (!PRESETn)
		raw_int <= 1'b0;
	else if (int_clr)
		raw_int <= 1'b0;
	else if (timer_en)
	begin
		if (auto_rld_sync2apb)
			raw_int <= 1'b1;
	end
end

//实际传送给CPU的中断信号，受到int_en门控影响
assign int_timer  = raw_int & int_en;

endmodule

