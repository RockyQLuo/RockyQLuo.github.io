module sig_deglitch
#(
	parameter   INIT_VAL = 1'b1 ,
	parameter   CNT_WID  = 5     
)
(
	input                       clk             , 
	input                       rst_n           , 
	input       [CNT_WID-1:0]   cfg_cnt         ,
	input                       key             ,
	output  reg                 key_no_glitch              
);


//---------------------------------------------------
wire                    key_change              ;
reg     [CNT_WID-1:0]   pulse_cnt               ;
reg                     last_value              ;
reg     [1:0]           key_syn                 ;
wire                    key0                    ;
wire                    deglitch_done           ;       
reg                     key0_r                  ;

//------------------  sync  -----------------------------------
always @(posedge clk or negedge rst_n)   
begin
	if (!rst_n)
		key_syn <= {2{INIT_VAL}};    
	else
		key_syn <= {key_syn[0], key};
end

assign key0 = key_syn[1];

always @(posedge clk or negedge rst_n)   
begin
	if (!rst_n)
		key0_r  <= INIT_VAL;    
	else
		key0_r  <= key0;
end

assign key_change = key0 ^ key0_r;

//--------------------  sync  --------------------------------------
always @(posedge clk or negedge rst_n)   
begin
	if (!rst_n)
		pulse_cnt   <= {CNT_WID{1'b0}};
	else
	begin
		if (key_change)
			pulse_cnt <= 1;
		else if (~(&pulse_cnt)) 
			pulse_cnt <= pulse_cnt + 1;
		//未写的else是溢出保护，等同于pulse_cnt等于全1时，计数器latch住
	end
end

assign deglitch_done  = (pulse_cnt >= cfg_cnt);

always @(posedge clk or negedge rst_n)   
begin
	if (!rst_n)
		last_value <= INIT_VAL; 
	else if (key_change & deglitch_done)
		last_value <= key0_r;
end

always @(posedge clk or negedge rst_n)   
begin
	if (!rst_n)
		key_no_glitch <= INIT_VAL; 
	else
	begin
		if (deglitch_done)
			key_no_glitch <= key0_r;
		else
			key_no_glitch <= last_value;
	end
end

endmodule

