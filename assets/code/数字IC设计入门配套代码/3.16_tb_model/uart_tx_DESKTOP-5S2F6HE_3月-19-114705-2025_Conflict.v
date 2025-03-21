module uart_tx
(
	input                 rst_n,
	input         [7:0]   char ,
	input                 trig , 
	output    reg         tx     
);
//----------------------------------------
reg             clk;
reg     [3:0]   cnt;
//----------------------------------------
initial
begin
	clk = 1'b0;

	forever
	begin
		#(1e9/(2.0*460800))  clk = ~clk;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if (~rst_n)
		cnt <= 4'd0;
	else 
	begin
		if (cnt == 4'd10)
			cnt <= 4'd0;
		else if (trig)
			cnt <= 4'd1;
		else if (cnt != 4'd0)
			cnt <= cnt + 4'd1;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if (~rst_n)
		tx <= 1'b1;
	else
	begin
		case (cnt)
			4'd1    : tx <= 1'b0;
			4'd2    : tx <= char[0];
			4'd3    : tx <= char[1];
			4'd4    : tx <= char[2];
			4'd5    : tx <= char[3];
			4'd6    : tx <= char[4];
			4'd7    : tx <= char[5];
			4'd8    : tx <= char[6];
			4'd9    : tx <= char[7];
			4'd10   : tx <= 1'b1;
			default : tx <= 1'b1;
		endcase
	end
end

endmodule

