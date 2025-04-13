module rco_model
(
	input             [6:0]   calib_word  ,
	input                     clk_en      ,
	output    logic           clk          
);
//-----------------------------------------
parameter STEP      = 41e6/2**7   ;
parameter CLK_BEGIN = 10e6        ;
//-----------------------------------------
real    freq        ;
logic   clk_en_dly  ;

//----------- freq --------------------
initial
begin
	forever
	begin
		freq = CLK_BEGIN + (2**7-calib_word) * STEP;
		#5e3;
	end
end

//----------- clk_en_delay --------------------
initial
begin
	clk_en_dly = 1'b0;

	fork
		forever 
		begin
			@(posedge clk_en);
			#1e3 clk_en_dly = clk_en;
		end

		forever
		begin
			@(negedge clk_en);
			clk_en_dly = clk_en;
		end
	join
end

initial
begin
	clk = 1'b0; 
	forever 
	begin
		#(1e9/(2.0*freq));
		if (clk_en_dly)
			clk = ~clk;
		else
			clk = 0;
	end
end

endmodule

