module ahb_rom_driver 
(
  input                 HCLK        ,      
  input                 HRESETn     ,   
  input                 HSEL        ,      
  input                 HREADY      ,    
  input         [1:0]   HTRANS      ,    
  input                 HWRITE      ,    
  input         [12:0]  HADDR       ,     
  output        [31:0]  HRDATA          
);   

//----------------------------------------------
wire                    sel             ;
wire                    rom_rd          ;
wire            [10:0]  rom_addr_inte   ;

//----------------------------------------------
//��ǰ����ͬ��sel�߼�
assign sel = HSEL & HTRANS[1] & HREADY;

//���߶�������ֱ�ӽ���ROM
assign rom_rd = sel & (~HWRITE);

//ROM��ַ
assign rom_addr_inte = HADDR[12:2];

//����ROM
rom     u_rom
(
	.CLK	(HCLK    	    ),//i   
	.CEN	(~rom_rd        ),//i 
	.A	    (rom_addr_inte	),//i[10:0]  
	.Q	    (HRDATA       	) //o[31:0]
);

endmodule
