`timescale 1ns/1ps
`define SVA
module tb;
//----------------------------------
logic           clk     ;
logic           rst_n   ;
logic           a       ;
wire            b       ;

//----------------------------------
initial
begin
	$fsdbDumpfile("tb.fsdb");
	$fsdbDumpvars(0);
	$fsdbDumpSVA(0);  //在fsdb中加入SVA信息
end

initial
begin
	clk = 0;
	forever #10 clk = ~clk;
end

initial
begin
	rst_n = 0;
	#50 rst_n = 1;
end

initial
begin
	a = 0;

	#1e2; @(posedge clk); a <= 1;
	#1e2; @(posedge clk); a <= 0;
	#1e2; @(posedge clk); a <= 1;
	#1e2; @(posedge clk); a <= 0;
	#1e2;

	$finish;
end

abc     u_abc
(
	.clk     (clk     ),//i
	.rst_n   (rst_n   ),//i
	.a       (a       ),//i
	.b       (b       ) //o   
);

endmodule

