module symme_timer
(
	input                       clk      ,
	input                       rst_n    ,
	input                       en       ,
	input           [31:0]      cfg_max  ,
	output      reg [31:0]      cnt          
);

//-------------------------------------------------
localparam  IDLE = 2'd0;
localparam  INC  = 2'd1;
localparam  DEC  = 2'd2;

//-------------------------------------------------
reg         [1:0]   stat            ;
reg         [1:0]   stat_next       ;
wire                max_pre_vld     ;
wire                one_vld         ;
wire        [31:0]  cfg_max_limit   ;

//-------------------------------------------------
assign cfg_max_limit = (cfg_max == 32'd0) ? 32'd1 : cfg_max;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		stat <= IDLE;
	else
		stat <= stat_next;
end

always @(*)
begin
	case (stat)
		IDLE:
		begin
			if (en)
				stat_next = INC;
			else
				stat_next = IDLE;
		end

		INC:
		begin
			if (~en)
				stat_next = IDLE;
			else if (max_pre_vld)
				stat_next = DEC;
			else
				stat_next = INC;
		end

		DEC:
		begin
			if (~en)
				stat_next = IDLE;
			else if (one_vld)
				stat_next = INC;
			else
				stat_next = DEC;
		end

		default: stat_next = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		cnt <= 32'd0;
	else if (stat == IDLE)
		cnt <= 32'd0;
	else if (stat == INC)
		cnt <= cnt + 32'd1;
	else if (stat == DEC)
		cnt <= cnt - 32'd1;
end

assign max_pre_vld = (cnt == cfg_max_limit - 32'd1);
assign one_vld = (cnt == 32'd1);

endmodule

