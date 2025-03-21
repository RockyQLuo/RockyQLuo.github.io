module spi_slave
(
    input               clk                 ,
    input               rst_n               ,

    input               CSn                 ,
    input               SCLK                ,
    input               MOSI                ,
    output  reg         MISO                ,  
    
    output              slave_byte_vld      ,        
    output  reg         wr_latch            ,
    output  reg         rd_latch            ,   

    output  reg [7:0]   slave_in            ,   
    input       [7:0]   slave_out_dat              
);

//-------------------------------------------------
localparam WR_OP = 8'h3c;
localparam RD_OP = 8'h5b;

//-------------------------------------------------
reg             SCLK_r                  ;
wire            SCLK_rise               ;
reg             SCLK_rise_r             ;
reg             SCLK_rise_2r            ;
reg     [3:0]   cnt                     ;
wire            slave_byte_vld_latch    ;
reg             slave_byte_vld_latch_r  ;
wire            slave_byte_vld_inner    ;
reg             op_phase                ;
reg             addr_finish             ;

//-------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        SCLK_r <= 1'b1;
    else if (CSn)
        SCLK_r <= 1'b1;
    else
        SCLK_r <= SCLK;
end

assign SCLK_rise    = SCLK    & (~SCLK_r)  ;

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        slave_in    <= 8'hff;
    else if (CSn)
        slave_in    <= 8'hff;
    else if (SCLK_rise)
        slave_in    <= {slave_in[6:0], MOSI};
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        cnt <= 4'd0;
    else if (CSn)
        cnt <= 4'd0;
    else if (SCLK_rise)
    begin
        if (cnt == 4'd8)
            cnt <= 4'd1;
        else
            cnt <= cnt + 4'd1;
    end
end

assign slave_byte_vld_latch = (cnt == 4'd8);

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        slave_byte_vld_latch_r <= 1'b0;
    else if (CSn)
        slave_byte_vld_latch_r <= 1'b0;
    else
        slave_byte_vld_latch_r <= slave_byte_vld_latch;
end

assign slave_byte_vld_inner = slave_byte_vld_latch & (~slave_byte_vld_latch_r);
assign slave_byte_vld       = slave_byte_vld_inner & (wr_latch | rd_latch);

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        op_phase <= 1'b1;
    else if (CSn)
        op_phase <= 1'b1;
    else if (slave_byte_vld_inner)
        op_phase <= 1'b0;
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        wr_latch <= 1'b0;
    else if (CSn)
        wr_latch <= 1'b0;
    else if (slave_byte_vld_inner & op_phase & (slave_in == WR_OP))
        wr_latch <= 1'b1;
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        rd_latch <= 1'b0;
    else if (CSn)
        rd_latch <= 1'b0;
    else if (slave_byte_vld_inner & op_phase & (slave_in == RD_OP))
        rd_latch <= 1'b1;
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        addr_finish <= 1'b0;
    else if (CSn)
        addr_finish <= 1'b0;
    else if (rd_latch & (cnt == 4'd7))
        addr_finish <= 1'b1;
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        SCLK_rise_r     <= 1'b0;
        SCLK_rise_2r    <= 1'b0;
    end
    else
    begin
        SCLK_rise_r     <= SCLK_rise    ;
        SCLK_rise_2r    <= SCLK_rise_r  ;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        MISO <= 1'b1;
    else if (CSn)
        MISO <= 1'b1;
    else if (SCLK_rise_2r)
    begin
        if (addr_finish)
        begin
            case (cnt)
                4'd8: MISO <= slave_out_dat[7];
                4'd1: MISO <= slave_out_dat[6];
                4'd2: MISO <= slave_out_dat[5];
                4'd3: MISO <= slave_out_dat[4];
                4'd4: MISO <= slave_out_dat[3];
                4'd5: MISO <= slave_out_dat[2];
                4'd6: MISO <= slave_out_dat[1];
                4'd7: MISO <= slave_out_dat[0];
            endcase
        end
        else
            MISO <= 1'b1;
    end
end

endmodule
