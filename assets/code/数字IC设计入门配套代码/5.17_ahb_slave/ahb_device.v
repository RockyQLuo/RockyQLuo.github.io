module ahb_device
(
	//AHB interface
	input               HCLK        ,
	input               HRESETn     ,
	input               HSEL        ,
	input               HREADY      ,
	input       [1:0]   HTRANS      ,
	input       [2:0]   HSIZE       ,
	input               HWRITE      ,
	input       [3:0]   HADDR       ,
	input       [31:0]  HWDATA      ,
	output  reg [31:0]  HRDATA      ,
	output              HREADYOUT   ,
	output              HRESP       ,

	//function
	output  reg [31:0]  cfg_dat0    ,     
	output  reg [31:0]  cfg_dat1    ,     
	output  reg [31:0]  cfg_dat2             
);   

// ----------------------------------------------
wire            sel         ;
wire            byt0        ;
wire            byt1        ;
wire            byt2        ;
wire            byt3        ;

reg             byt0_r      ;
reg             byt1_r      ;
reg             byt2_r      ;
reg             byt3_r      ;

reg     [1:0]   addr_inte   ;

// -----------------------------------------------
assign sel = HSEL & HTRANS[1] & HREADY;
assign byt0= HSIZE[1] | (HSIZE[0] & (~HADDR[1])) | (HADDR[1:0]==2'b00);
assign byt1= HSIZE[1] | (HSIZE[0] & (~HADDR[1])) | (HADDR[1:0]==2'b01);
assign byt2= HSIZE[1] | (HSIZE[0] & HADDR[1])    | (HADDR[1:0]==2'b10);
assign byt3= HSIZE[1] | (HSIZE[0] & HADDR[1])    | (HADDR[1:0]==2'b11);

always @(posedge HCLK or negedge HRESETn)
begin
	if (!HRESETn)
	begin
		byt0_r      <= 1'b0;
		byt1_r      <= 1'b0;
		byt2_r      <= 1'b0;
		byt3_r      <= 1'b0;
		addr_inte   <= 2'd0;
	end
	else
	begin
		byt0_r      <= byt0 & HWRITE & sel;
		byt1_r      <= byt1 & HWRITE & sel;
		byt2_r      <= byt2 & HWRITE & sel;
		byt3_r      <= byt3 & HWRITE & sel;
		addr_inte   <= HADDR[3:2]   ;
	end
end

// ---------  write  ------------
always @(posedge HCLK or negedge HRESETn)
begin
	if (!HRESETn)
		cfg_dat0 <= 32'd0;
	else
	begin
		if (byt0_r & (addr_inte == 2'd0))
			cfg_dat0[7:0]   <= HWDATA[7:0];

		//注意：不是else if，而是if。将若干个always块的逻辑合并为一个
		if (byt1_r & (addr_inte == 2'd0))
			cfg_dat0[15:8]  <= HWDATA[15:8];

		if (byt2_r & (addr_inte == 2'd0))
			cfg_dat0[23:16] <= HWDATA[23:16];

		if (byt3_r & (addr_inte == 2'd0))
			cfg_dat0[31:24] <= HWDATA[31:24];
	end
end

always @(posedge HCLK or negedge HRESETn)
begin
	if (!HRESETn)
		cfg_dat1 <= 32'd0;
	else
	begin
		if (byt0_r & (addr_inte == 2'd1))
			cfg_dat1[7:0]   <= HWDATA[7:0];

		if (byt1_r & (addr_inte == 2'd1))
			cfg_dat1[15:8]  <= HWDATA[15:8];

		if (byt2_r & (addr_inte == 2'd1))
			cfg_dat1[23:16] <= HWDATA[23:16];

		if (byt3_r & (addr_inte == 2'd1))
			cfg_dat1[31:24] <= HWDATA[31:24];
	end
end

always @(posedge HCLK or negedge HRESETn)
begin
	if (!HRESETn)
		cfg_dat2 <= 32'd0;
	else
	begin
		if (byt0_r & (addr_inte == 2'd2))
			cfg_dat2[7:0]   <= HWDATA[7:0];

		if (byt1_r & (addr_inte == 2'd2))
			cfg_dat2[15:8]  <= HWDATA[15:8];

		if (byt2_r & (addr_inte == 2'd2))
			cfg_dat2[23:16] <= HWDATA[23:16];

		if (byt3_r & (addr_inte == 2'd2))
			cfg_dat2[31:24] <= HWDATA[31:24];
	end
end

//------------ read ---------------
//注意：这里读操作是组合逻辑，固定输出32位
always @(*)
begin
	//注意：这里使用了addr_inte，而非HADDR
	case (addr_inte)
		2'd0    : HRDATA = cfg_dat0;
		2'd1    : HRDATA = cfg_dat1;
		2'd2    : HRDATA = cfg_dat2;
		default : HRDATA = 32'd0; 
	endcase
end

assign HREADYOUT = 1'b1;
assign HRESP     = 1'b0;

endmodule

