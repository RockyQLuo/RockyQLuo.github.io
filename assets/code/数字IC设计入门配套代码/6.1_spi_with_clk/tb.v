`timescale 1ns/1ps

module tb;

//-------------------------------------------
//clk / rst_n    
logic                   master_clk              ;
logic                   slave_clk               ;
logic                   rst_n                   ;

//interface
wire                    CSn                     ;
wire                    SCLK                    ;
wire                    MOSI                    ;
wire                    MISO                    ;

//master
logic                   trig                    ;
logic                   wr                      ;
logic       [7:0]       len                     ;
logic                   master_base_addr_req    ;
logic       [7:0]       wdat                    ;
wire                    wdat_req                ;
wire                    trans_over              ;
logic       [7:0]       master_addr             ;
logic       [7:0]       master_mem[7:0]         ;
wire        [7:0]       rdat                    ;
wire                    rdat_vld                ;

//slave
logic                   slave_base_addr_req     ;
logic       [7:0]       slave_addr              ;
wire                    slave_byte_vld          ;
wire        [7:0]       slave_in                ;
wire        [7:0]       slave_out_dat           ;
logic       [7:0]       slave_mem[7:0]          ;
wire                    wr_latch                ;
wire                    rd_latch                ;

//-------------------------------------------
initial
begin
    $fsdbDumpfile("tb.fsdb");
    $fsdbDumpvars(0);
    $fsdbDumpMDA(tb.master_mem);
    $fsdbDumpMDA(tb.slave_mem);
end

//---------------  Master  -------------------------
initial
begin
    master_clk = 1'b0; 
    forever 
    begin
        #(1e9/(2.0*80e6)) master_clk = ~master_clk;
    end
end

initial
begin
    slave_clk = 1'b0; 
    #1;
    forever 
    begin
        #(1e9/(2.0*160e6)) slave_clk = ~slave_clk;
    end
end

initial
begin
    rst_n = 0;
    #30 rst_n = 1;
end

initial
begin
    trig    = 1'b0;
    wr      = 1'b0;
    len     = 8'd0;
    wdat    = 8'hff;
    @(posedge rst_n);
    #1000;

    @(posedge master_clk);
    trig    <= 1'b1;
    wr      <= 1'b1;
    len     <= 8'd3;
    
    @(posedge master_clk);
    trig    <= 1'b0;

    @(negedge trans_over);
    #1000;

    @(posedge master_clk);
    trig    <= 1'b1;
    wr      <= 1'b0;
    len     <= 8'd3;
    
    @(posedge master_clk);
    trig    <= 1'b0;

    @(negedge trans_over);
    #1000;
    $finish;
end

initial
begin
    master_mem[0]  = 8'h00;
    master_mem[1]  = 8'h11;
    master_mem[2]  = 8'h21;
    master_mem[3]  = 8'h31;
    master_mem[4]  = 8'h42;
    master_mem[5]  = 8'h52;
    master_mem[6]  = 8'h63;
    master_mem[7]  = 8'h73;
end

initial
begin
    wdat = 8'hff;
    forever
    begin
        @(negedge wdat_req);       
        if (master_base_addr_req)
            wdat <= master_addr;
        else
            wdat <= master_mem[master_addr];
    end
end

initial
begin
    master_addr = 8'h00;

    forever
    begin
        fork
            begin
                @(posedge trig);
                master_addr <= 8'h02;
            end

            begin
                @(negedge wdat_req);
                if (~master_base_addr_req)
                    master_addr <= master_addr + 8'h01;
            end
        join_any
    end
end

initial
begin
    master_base_addr_req = 1'b0;

    forever
    begin
        fork
            begin
                @(negedge CSn);
                master_base_addr_req <= 1'b1;
            end

            begin
                @(negedge wdat_req);
                master_base_addr_req <= 1'b0;
            end
        join_any
    end
end

//---------------  Slave  -------------------------
initial
begin
    slave_base_addr_req = 1'b0;

    forever
    begin
        fork
            begin
                @(negedge CSn);
                slave_base_addr_req <= 1'b1;
            end

            begin
                @(negedge slave_byte_vld);
                slave_base_addr_req <= 1'b0;
            end
        join_any
    end
end

initial
begin
    slave_addr = 8'd0;
    
    forever
    begin
        @(posedge slave_clk);
        if (slave_byte_vld)
        begin
            if (slave_base_addr_req)
                slave_addr <= slave_in;
            else
                slave_addr <= slave_addr + 8'd1;
        end
    end
end

initial
begin
    slave_mem[0]  = 8'h00;
    slave_mem[1]  = 8'h00;
    slave_mem[2]  = 8'h00;
    slave_mem[3]  = 8'h00;
    slave_mem[4]  = 8'h00;
    slave_mem[5]  = 8'h00;
    slave_mem[6]  = 8'h00;
    slave_mem[7]  = 8'h00;

    forever
    begin
        @(posedge slave_clk);
        if (slave_byte_vld & wr_latch & (~slave_base_addr_req))
            slave_mem[slave_addr] <= slave_in;
    end
end

assign slave_out_dat = slave_mem[slave_addr];


//------------------------------------------------------------
spi_master      u_spi_master
(
    .clk         (master_clk  ),//i        
    .rst_n       (rst_n       ),//i        

    .trig        (trig        ),//i        
    .wr          (wr          ),//i        
    .len         (len         ),//i[7:0]   
    .wdat        (wdat        ),//i[7:0]   
    .wdat_req    (wdat_req    ),//o        
    .rdat        (rdat        ),//o[7:0]   
    .rdat_vld    (rdat_vld    ),//o        
    .trans_over  (trans_over  ),//o

    .CSn         (CSn         ),//o        
    .SCLK        (SCLK        ),//o        
    .MOSI        (MOSI        ),//o        
    .MISO        (MISO        ) //i           
);

spi_slave       u_spi_slave
(
    .clk                 (slave_clk         ),//i
    .rst_n               (rst_n             ),//i

    .CSn                 (CSn               ),//i        
    .SCLK                (SCLK              ),//i        
    .MOSI                (MOSI              ),//i        
    .MISO                (MISO              ),//o          

    .slave_byte_vld      (slave_byte_vld    ),//o                
    .wr_latch            (wr_latch          ),//o
    .rd_latch            (rd_latch          ),//o
    .slave_in            (slave_in          ),//o[7:0]      
    .slave_out_dat       (slave_out_dat     ) //i[7:0]   
);

endmodule

