`timescale 1ns/1ps

module tb;
//------------------------------------
reg             clk_A   ;
reg             clk_B   ;
reg             rstn_A  ;
reg             rstn_B  ;
reg             sel     ;


//------------------------------------
initial
begin
    $fsdbDumpfile("tb_asic.fsdb");
    $fsdbDumpvars(0);
end

initial
begin
    clk_A = 1'b0;
    
    #100;
    forever
    begin
        #100 clk_A = ~clk_A;
    end
end


initial
begin
    clk_B = 1'b0;
    
    #77;
    forever
    begin
        #27 clk_B = ~clk_B;
    end
end


initial
begin
    rstn_A = 1'b0;
    #1e3;
    @(posedge clk_A) rstn_A = 1'b1;
end


initial
begin
    rstn_B = 1'b0;
    #1e3;
    @(posedge clk_B) rstn_B = 1'b1;
end


initial
begin
    sel = 1'b0;

    #5e3;   sel = 1'b1;
    #5e3;   sel = 1'b0;
    #5e3;   $finish;
end


//-------------------------------
clk_switch4      u_clk_switch4  
(
    .clk_A      (clk_A      ),//i  
    .clk_B      (clk_B      ),//i
    .rstn_A     (rstn_A     ),//i
    .rstn_B     (rstn_B     ),//i
    .sel        (sel        ),//i
    .clk_out    (           ) //o   
);


endmodule


