module atan
(
    input                       clk         ,
    input                       rst_n       ,
    
    input                       trig        ,
    output                      vld         ,

    input       signed  [16:0]  para_in     ,
    output  reg signed  [11:0]  atany            
);


//-----------------------------------------
reg                     run_latch   ;
reg             [3:0]   cnt         ;
reg     signed  [18:0]  tmp1        ;
reg     signed  [18:0]  tmp2        ;
wire    signed  [19:0]  y0          ;
reg     signed  [19:0]  xr          ;
reg     signed  [19:0]  yr          ;
reg     signed  [19:0]  x2          ;
reg     signed  [19:0]  y2          ;



always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        run_latch <= 1'b0;
    else
    begin
        if (trig)
            run_latch <= 1'b1;
        else if (cnt == 4'd9)
            run_latch <= 1'b0;
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        cnt <= 4'd0;
    else
    begin
        if (run_latch)
            cnt <= cnt + 4'd1;
        else
            cnt <= 4'd0;
    end
end


assign vld = (cnt == 4'd10);
assign y0 = para_in<<2;


always @(*)
begin
    if (run_latch)
    begin
        case(cnt)
            4'd0:
            begin
                tmp1 = y2>>>1;
                tmp2 = x2>>>1;
            end
            4'd1:
            begin
                tmp1 = y2>>>2;
                tmp2 = x2>>>2;
            end
            4'd2:
            begin
                tmp1 = y2>>>3;
                tmp2 = x2>>>3;
            end
            4'd3:
            begin
                tmp1 = y2>>>4;
                tmp2 = x2>>>4;
            end
            4'd4:
            begin
                tmp1 = y2>>>5;
                tmp2 = x2>>>5;
            end
            4'd5:
            begin
                tmp1 = y2>>>6;
                tmp2 = x2>>>6;
            end
            4'd6:
            begin
                tmp1 = y2>>>7;
                tmp2 = x2>>>7;
            end
            4'd7:
            begin
                tmp1 = y2>>>8;
                tmp2 = x2>>>8;
            end
            4'd8:
            begin
                tmp1 = y2>>>9;
                tmp2 = x2>>>9;
            end
            4'd9:
            begin
                tmp1 = y2>>>10;
                tmp2 = x2>>>10;
            end
            default:     
            begin
                tmp1 = 19'd0;
                tmp2 = 19'd0;
            end
        endcase
    end
    else
    begin
        tmp1 = 19'd0;
        tmp2 = 19'd0;
    end
end


always @(*)
begin
    if (run_latch)
    begin
        if ((x2[19] == y2[19]) | (x2 == 20'd0) | (y2 == 20'd0))
        begin
            xr = x2 + tmp1;
            yr = y2 - tmp2;
        end
        else
        begin
            xr = x2 - tmp1;
            yr = y2 + tmp2;
        end
    end
    else
    begin
        xr = 20'd0;
        yr = 20'd0;
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        x2 <= 20'd0;
        y2 <= 20'd0;
    end
    else
    begin
        if (trig)
        begin
            if (~para_in[16]) 
            begin
                x2 <= 20'd1024 + y0;
                y2 <= y0 - 20'd1024;
            end
            else  
            begin
                x2 <= 20'd1024 - y0;
                y2 <= y0 + 20'd1024;
            end
        end
        else if (run_latch)
        begin
            x2 <= xr;
            y2 <= yr;
        end
    end
end


always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        atany <= 12'd0;
    else 
    begin
        if (trig)
        begin
            if (~para_in[16]) 
                atany <= 12'd804;
            else 
                atany <= 12'd3292;
        end
        else if (run_latch)
        begin
            case (cnt)
                4'd0: 
                begin
                    if ((x2[19] == y2[19]) | (x2 == 20'd0) | (y2 == 20'd0))
                        atany <= atany + 12'd475;
                    else
                        atany <= atany - 12'd475;
                end
                4'd1: 
                begin
                    if ((x2[19] == y2[19]) | (x2 == 20'd0) | (y2 == 20'd0)) 
                        atany <= atany + 12'd251;
                    else
                        atany <= atany - 12'd251;
                end
                4'd2: 
                begin
                    if ((x2[19] == y2[19]) | (x2 == 20'd0) | (y2 == 20'd0)) 
                        atany <= atany + 12'd127;
                    else
                        atany <= atany - 12'd127;
                end
                4'd3: 
                begin
                    if ((x2[19] == y2[19]) | (x2 == 20'd0) | (y2 == 20'd0))
                        atany <= atany + 12'd64;
                    else
                        atany <= atany - 12'd64;
                end
                4'd4: 
                begin
                    if ((x2[19] == y2[19]) | (x2 == 20'd0) | (y2 == 20'd0))
                        atany <= atany + 12'd32;
                    else
                        atany <= atany - 12'd32;
                end
                4'd5: 
                begin
                    if ((x2[19] == y2[19]) | (x2 == 20'd0) | (y2 == 20'd0))
                        atany <= atany + 12'd16;
                    else
                        atany <= atany - 12'd16;
                end
                4'd6: 
                begin
                    if ((x2[19] == y2[19]) | (x2 == 20'd0) | (y2 == 20'd0))
                        atany <= atany + 12'd8;
                    else
                        atany <= atany - 12'd8;
                end
                4'd7: 
                begin
                    if ((x2[19] == y2[19]) | (x2 == 20'd0) | (y2 == 20'd0))
                        atany <= atany + 12'd4;
                    else
                        atany <= atany - 12'd4;
                end
                4'd8: 
                begin
                    if ((x2[19] == y2[19]) | (x2 == 20'd0) | (y2 == 20'd0))
                        atany <= atany + 12'd2;
                    else
                        atany <= atany - 12'd2;
                end
                4'd9: 
                begin
                    if ((x2[19] == y2[19]) | (x2 == 20'd0) | (y2 == 20'd0))
                        atany <= atany + 12'd1;
                    else
                        atany <= atany - 12'd1;
                end
            endcase
        end
    end
end

endmodule

