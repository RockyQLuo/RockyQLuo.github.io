module clk_switch4
(
	input    clk_A   ,
	input    clk_B   ,
	input    rstn_A  ,
	input    rstn_B  ,
	input    sel     ,
	output   clk_out  
);

//------------------------------------------------
wire    a1o;
reg     a1o_r ;
reg     a1o_sync;
wire    a2o;
wire    a3o;
reg     a3o_r;
reg     a3o_sync;
wire    a4o;
wire    a1i_2;
wire    a3i_2;

//------------ 上面的电路部分 ------------------------
assign a1o = sel | a1i_2;  //A1改为或门输出

always @(posedge clk_A or negedge rstn_A)  
begin
	if (!rstn_A)
	begin
		a1o_r       <= 1'b0;   //初值改了，由于0表示开启，1表示关闭
		a1o_sync    <= 1'b0;  //默认上面电路先开启，所以初值应为0 
	end
	else
	begin
		a1o_r       <= a1o;
		a1o_sync    <= a1o_r;
	end
end

assign a2o = clk_A | a2i_2;  //clk_A门控改为或门输出

//------------- 下面的电路部分 -----------------------------------
assign a3o = (~sel) | a3i_2;  //A3改为或门输出

always @(posedge clk_B or negedge rstn_B)  //上升沿采样的同步器
begin
	if (!rstn_B)
	begin
		a3o_r       <= 1'b1; //初值改为1，即默认关闭
		a3o_sync    <= 1'b1;
	end
	else
	begin
		a3o_r       <= a3o;
		a3o_sync    <= a3o_r;
	end
end

assign a4o = clk_B | a4i_2; //clk_B门控改为输出


//------------- 两个电路交叉的非门部分 -----------------------------------
assign a1i_2 = ~a3o_sync;
assign a3i_2 = ~a1o_sync;


//-------------- 改为与门输出 ----------------------------------
assign clk_out = a2o & a4o;


endmodule

