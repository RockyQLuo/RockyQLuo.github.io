module spi_slave
(
    input               CSn                 ,
    input               SCLK                ,
    input               MOSI                ,
    output  reg         MISO                ,  
    
    input               sclk_rstn           ,   
    
    output              slave_byte_vld_pre  ,        
    output  reg         wr_latch            ,
    output  reg         rd_latch            ,   

    output  reg [7:0]   slave_in            ,   
    input       [7:0]   slave_out_dat              
);

//-------------------------------------------------
localparam WR_OP = 8'h3c;
localparam RD_OP = 8'h5b;

//-------------------------------------------------
reg     [15:0]  cnt                 ;
wire    [15:0]  cnt2                ;
wire            dat_rcv_clk         ;
wire            CSn2                ;


//--------------  common ----------------------
assign dat_rcv_clk = SCLK & (~CSn); //generate new clock

always @(posedge dat_rcv_clk or negedge sclk_rstn)
begin
    if (!sclk_rstn)
        cnt <= 16'd0;
    else
        cnt <= cnt2 + 16'd1;
end

assign #0.01 CSn2 = CSn;
assign cnt2 = (~CSn2) ? cnt : 16'd0;


always @(posedge SCLK or negedge sclk_rstn)
begin
    if (!sclk_rstn)
        slave_in <= 8'hff;
    else
        slave_in <= {slave_in[6:0], MOSI};
end

// ------------- get operation ------------------
always @(posedge SCLK or negedge sclk_rstn)
begin
    if (!sclk_rstn)
    begin
        wr_latch <= 1'b0;
        rd_latch <= 1'b0;
    end
    else if (cnt2 == 16'd9)
    begin
        wr_latch <= (slave_in == WR_OP); 
        rd_latch <= (slave_in == RD_OP); 
    end
end

// ------------- get data ------------------
assign slave_byte_vld_pre = (cnt2[2:0] == 3'd1) & (cnt2 >= 16'd17);


// ------------- send data ------------------
always @(*)
begin
    if ((cnt2 >= 16'd17) & rd_latch)
    begin
        case (cnt2[2:0])
            3'd1: MISO = slave_out_dat[7];
            3'd2: MISO = slave_out_dat[6];
            3'd3: MISO = slave_out_dat[5];
            3'd4: MISO = slave_out_dat[4];
            3'd5: MISO = slave_out_dat[3];
            3'd6: MISO = slave_out_dat[2];
            3'd7: MISO = slave_out_dat[1];
            3'd0: MISO = slave_out_dat[0];
        endcase
    end
    else
        MISO = 1'b1;
end


endmodule

