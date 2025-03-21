timescale 1ns/1ps

module tb;

//-------------------------------------------
int                     fsdbDump        ;
integer                 seed            ;

//clk / rstn    
logic                   clk             ;
logic                   rstn            ;
reg                     en              ;

//-------------------------------------------
// Format for time reporting
initial    $timeformat(-9, 3, " ns", 0);
initial
begin
    if (!$value$plusargs("seed=%d", seed))
        seed = 100;
    $srandom(seed);
    $display("seed = %d\n", seed);

    if(!$value$plusargs("fsdbDump=%d",fsdbDump))
        fsdbDump = 1;
    if (fsdbDump)
    begin
        $fsdbDumpfile("tb.fsdb");
        $fsdbDumpvars(0);
    end
end

//-----------------------------------------------------------
initial
begin
    clk = 1'b0; 
    forever 
    begin
        #(1e9/(2.0*40e6)) clk = ~clk;
    end
end

initial
begin
    rstn = 0;
    #30 rstn = 1;
end

initial
begin
    en     = 0;

    @(posedge rstn);
    #100;
    @(posedge clk);
    #1;
    en = 1;

    #1000;
    @(posedge clk);
    #1;
    en = 0;
    
    #100;
    $finish;
end


//------------------------------------------------------------
symme_timer     u_symme_timer
(
    .clk            (clk        ),//i            
    .rst_n          (rstn       ),//i            
    .en             (en         ),//i
    .cfg_max        (5          ),//i            
    .cnt            (           ) //o
);



endmodule

