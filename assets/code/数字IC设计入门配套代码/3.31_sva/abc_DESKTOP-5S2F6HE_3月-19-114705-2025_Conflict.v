module abc
(
	input               clk     ,
	input               rst_n   ,
	input               a       ,
	output reg          b           
);

//------------ RTL 代码部分  ----------------------
always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		b <= 1'b0;
	else
		b <= ~a;
end

//------------ SVA断言部分  ----------------------
`ifdef SVA
	Bis0: assert property(Evt_b0)
	else
		$error("b is not 0 @ %t", $time);

	Bis1: assert property(Evt_b1)
	else
		$display("b is not 1 @ %t", $time);

	property Evt_b0;
		@(posedge clk) a |-> ##1 ~b;       
	endproperty

	property Evt_b1;
		@(posedge clk) (rst_n && ~a) |-> ##1 b;
	endproperty
`endif

endmodule



