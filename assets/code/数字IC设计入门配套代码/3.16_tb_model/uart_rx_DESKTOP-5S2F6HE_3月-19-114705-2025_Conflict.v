module uart_rx 
(
	input           rst_n ,
	input           rx     
);            
//---------------------------------------------------
reg             clk;
reg     [3:0]   cnt;
reg             uartfinish;
reg     [7:0]   sreg;

//---------------------------------------------------
initial
begin
	clk = 1'b0;

	forever
	begin
		#(1e9/(2.0*460800))  clk = ~clk;
	end
end

//触发接收数据
assign trig = (cnt == 4'd0) & (~rx);

//接收并存储数据
always @(posedge clk or negedge rst_n)
begin
	if (~rst_n)
		sreg <= 8'hff;
	else
	begin
		case (cnt)
			4'd1    : sreg[0] <= rx;
			4'd2    : sreg[1] <= rx;
			4'd3    : sreg[2] <= rx;
			4'd4    : sreg[3] <= rx;
			4'd5    : sreg[4] <= rx;
			4'd6    : sreg[5] <= rx;
			4'd7    : sreg[6] <= rx;
			4'd8    : sreg[7] <= rx;
			default : sreg    <= sreg;
		endcase
	end
end

//接收比特计数
always @(posedge clk or negedge rst_n)
begin
	if (~rst_n)
		cnt <= 4'd0;
	else 
	begin
		if (cnt == 4'd8)
			cnt <= 4'd0;
		else if (trig)
			cnt <= 4'd1;
		else if (cnt != 4'd0)
			cnt <= cnt + 4'd1;
	end
end

//一个字节接收完成
always @(posedge clk or negedge rst_n)
begin
	if (~rst_n)
		uartfinish <= 1'b0;
	else
		uartfinish <= (cnt == 4'd8);
end

//打印收到的字节
always @(posedge clk)
begin
	if(uartfinish) 
	begin
		if (sreg == 8'h0A) 
			$write("\n");
		else
			$write("%c",sreg);
    end
end 

endmodule

