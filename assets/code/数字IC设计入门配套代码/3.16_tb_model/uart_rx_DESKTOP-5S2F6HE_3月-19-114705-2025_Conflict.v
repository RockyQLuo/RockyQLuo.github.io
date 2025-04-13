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

//������������
assign trig = (cnt == 4'd0) & (~rx);

//���ղ��洢����
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

//���ձ��ؼ���
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

//һ���ֽڽ������
always @(posedge clk or negedge rst_n)
begin
	if (~rst_n)
		uartfinish <= 1'b0;
	else
		uartfinish <= (cnt == 4'd8);
end

//��ӡ�յ����ֽ�
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

