module spi_master
(
    input               clk         ,
    input               rst_n       ,
    
    input               trig        ,
    input               wr          ,
    input       [7:0]   len         ,
    input       [7:0]   wdat        ,
    output              wdat_req    ,
    output  reg [7:0]   rdat        ,
    output  reg         rdat_vld    ,
    output  reg         trans_over  ,

    output  reg         CSn         ,
    output  reg         SCLK        ,
    output  reg         MOSI        ,
    input               MISO            
);

//-------------------------------------------------
localparam WR_OP = 8'h3c;
localparam RD_OP = 8'h5b;

//-------------------------------------------------
reg     [31:0]      cnt             ;
wire    [31:0]      final_num       ;
wire                wdat_req_mask   ;
wire                cnt_end         ;
reg     [7:0]       sending_tmp     ;
reg     [7:0]       rdat_tmp        ;
wire                rdat_last_vld   ;
reg                 rdat_last_r     ;
reg                 wdat_req_r      ;

//-------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        cnt <= 32'd0;
    else if (trig)
        cnt <= 32'd1;
    else if (cnt_end)
        cnt <= 32'd0;
    else if (~CSn)
        cnt <= cnt + 32'd1;
end

assign final_num     = ((8'd2+len) << 4) - 32'd1;
assign wdat_req_mask = (cnt == final_num);
assign cnt_end       = (cnt == final_num + 32'd2);

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        trans_over <= 1'b0;
    else
        trans_over <= cnt_end;
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        CSn <= 1'b1;
    else
    begin
        if (trig)
            CSn <= 1'b0;
        else if (cnt_end)
            CSn <= 1'b1;
    end
end

always @(*)
begin
    if (cnt == 32'd0)
        SCLK = 1'b1;
    else if (cnt[0] == 1'b1)
        SCLK = 1'b1;
    else
        SCLK = 1'b0;
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        sending_tmp <= 8'hff;
    else
    begin
        if ((cnt == 32'd0) & trig)
        begin
            if (wr)
                sending_tmp <= WR_OP;
            else
                sending_tmp <= RD_OP;
        end
        else if (wdat_req_r)
            sending_tmp <= wdat;
        else if (cnt[0] == 1'b1)
            sending_tmp <= (sending_tmp << 1);
    end
end

assign wdat_req =  ((cnt[3:0] == 4'hf) & wr & (~wdat_req_mask))
                 | (cnt == 4'hf);

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        wdat_req_r <= 1'b0;
    else
        wdat_req_r <= wdat_req;
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        MOSI <= 1'b1;
    else
    begin
        if (cnt == 32'd0)
            MOSI <= 1'b1;
        else if (cnt[0] == 1'b1)
            MOSI <= sending_tmp[7];
    end
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        rdat_tmp <= 8'd0;
    else
    begin
        if (cnt == 32'd0)
            rdat_tmp <= 8'd0;
        else if ((cnt[0] == 1'b0) & (cnt > 32'd16) & (~wr))
            rdat_tmp <= {rdat_tmp[6:0], MISO};
    end
end

assign rdat_last_vld = (cnt[3:0] == 4'd0) & (cnt > 32'd32) & (~wr);

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        rdat_last_r <= 1'b0;
        rdat_vld    <= 1'b0;
    end
    else
    begin
        rdat_last_r <= rdat_last_vld;
        rdat_vld    <= rdat_last_r;
    end
end

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        rdat <= 8'hff;
    else if (rdat_last_r)
        rdat <= rdat_tmp;
end


endmodule

