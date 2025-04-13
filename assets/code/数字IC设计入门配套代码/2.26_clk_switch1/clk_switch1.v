module clk_switch1
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
reg     a2i_2;
wire    a2o;
wire    a3o;
reg     a3o_r;
reg     a3o_sync;
reg     a4i_2;
wire    a4o;
wire    a1i_2;
wire    a3i_2;

//------------ 上面的电路部分 ------------------------
assign a1o = (~sel) & a1i_2;  //A1与门输出

always @(posedge clk_A or negedge rstn_A)  //上升沿采样的同步器
begin
	if (!rstn_A)
	begin
		//这些初值设为1，因为假设sel复位时为0，会选中clk_A作为默认输出时钟
		//所以它的门控必须在复位时就已经打开
		a1o_r       <= 1'b1;
		a1o_sync    <= 1'b1; 
	end
	else
	begin
		a1o_r       <= a1o;
		a1o_sync    <= a1o_r;
	end
end

always @(negedge clk_A or negedge rstn_A)  //下降沿采样的寄存器
begin
	if (!rstn_A)
		a2i_2 <= 1'b1;     //复位时默认打开clk_A门控
	else
		a2i_2 <= a1o_sync;
end

assign a2o = clk_A & a2i_2;  //clk_A门控时钟输出

//------------- 下面的电路部分 -----------------------------------
assign a3o = sel & a3i_2;  //A3与门输出

always @(posedge clk_B or negedge rstn_B)  //上升沿采样的同步器
begin
	if (!rstn_B)
	begin
		a3o_r       <= 1'b0;       //复位时默认关闭clk_B门控
		a3o_sync    <= 1'b0;
	end
	else
	begin
		a3o_r       <= a3o;
		a3o_sync    <= a3o_r;
    end
end

always @(negedge clk_B or negedge rstn_B)  //下降沿采样的寄存器
begin
	if (!rstn_B)
		a4i_2 <= 1'b0;
	else
		a4i_2 <= a3o_sync;
end

assign a4o = clk_B & a4i_2; //clk_B门控时钟输出

//------------- 两个电路交叉的非门部分 -----------------------------------
assign a1i_2 = ~a4i_2;
assign a3i_2 = ~a2i_2;

//-------------- 或门输出 ----------------------------------
assign clk_out = a2o | a4o;

endmodule

