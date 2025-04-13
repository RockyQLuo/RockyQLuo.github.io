module clk_switch3
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
reg     a1o_r;
reg     a1o_sync;
wire    a2o;
wire    a3o;
reg     a3o_r;
reg     a3o_sync;
wire    a4o;
wire    a1i_2;
wire    a3i_2;

//------------ 上面的电路部分 ------------------------
assign a1o = (~sel) & a1i_2;  

always @(posedge clk_A or negedge rstn_A)  //与切换电路一相同的同步结构 
begin
	if (!rstn_A)
	begin
		a1o_r       <= 1'b1;    
		a1o_sync    <= 1'b1;   
	end 
	else
	begin
		a1o_r       <= a1o;
		a1o_sync    <= a1o_r;
	end
end

assign a2o = (~clk_A) & a1o_sync;  //clk_A取反后直接使用a1o_sync作为门控

//------------- 下面的电路部分 -----------------------------------
assign a3o = sel & a3i_2;  

always @(posedge clk_B or negedge rstn_B)  //与切换电路一相同的同步结构
begin
	if (!rstn_B)
	begin
		a3o_r       <= 1'b0;       
		a3o_sync    <= 1'b0;
	end
	else
	begin
		a3o_r       <= a3o;
		a3o_sync    <= a3o_r;
	end
end

assign a4o = (~clk_B) & a3o_sync; // clk_B取反后直接使用a3o_sync作为门控

//------------- 两个电路交叉的非门部分 -----------------------------------
assign a1i_2 = ~a3o_sync;
assign a3i_2 = ~a1o_sync;

//-------------- 或门输出 ----------------------------------
assign clk_out = ~(a2o | a4o); //取或之后还要加一步反相

endmodule

