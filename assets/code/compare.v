module aaa ();

  reg clk;
  reg rstn;
  reg valid_i;
  reg ready_i;
  reg [31:0] data_i;
  wire [31:0] data_o;
  wire ready_o;
  wire valid_o;

  initial begin
    clk = 1'b0;
    forever
    #10 begin
      clk = -clk;
    end
  end

  initial begin
    rstn = 1'b0;
    #13;
    rstn = 1'b1;
  end

  reg [1:0] rstn_dff;

  always @(posedge clk or negedge rstn_dff[1]) begin
    if (!rstn) rstn_dff <= 2'b00;
    else rstn_dff <= {rstn_dff[0], rstn};
  end

  initial begin
    ready_i = 1'b1;
  end

  // Declare state


  localparam IDLE = 3'b000;
  localparam BEAT1 = 3'b001;
  localparam BEAT2 = 3'b010;
  localparam BEAT3 = 3'b011;
  localparam BEAT4 = 3'b100;

  reg [2:0] cur_state;
  reg [2:0] nxt_state;

  always @(posedge clk or negedge rstn_dff[1]) begin
    if (!rstn_dff[1]) cur_state <= IDLE;
    else cur_state <= nxt_stae;
  end

  // wait for 63 cycle


  reg [5:0] clk_cnt;
  wire start_tx = (clk_cnt == 6'b11_1110);

  always @(posedge clk or negedge rstn_dff[1]) begin
    if (!rstn_dff[1]) clk_cnt <= 6'h0;
    else if (clk_cnt == 6'b11_1111) clk_cnt <= clk_cnt;
    else clk_cnt <= clk_cnt + 1'b1;
  end

  always @(*) begin
    case (cur_state)
      IDLE:  if (start_tx) nxt_state = BEAT1;
 else nxt_state = IDLE;
      BEATI: if (valid_i && ready_o) nxt_state = BEAT2;
 else nxt_state = BEAT1;
      BEAT2: if (valid_i && ready_o) nxt_state = BEAT3;
 else nxt_state = BEAT2;
      BEAT3: if (valid_i && ready_o) nxt_state = BEAT4;
 else nxt_state = BEAT3;
      BEAT4: if (valid_i && ready_o) nxt_state = IDLE;
 else nxt_state = BEAT4;

      default: nxt_state = IDLE;
    endcase
  end

  // Generate valid and data
  wire update_en = (nxt_state == BEAT2) || (nxt_state == BEAT3) || (nxt_state == BEAT4);

  always @(posedge clk or negedge rstn_dff[1]) begin
    if (!rstn_dff[1]) begin
      valid_i <= 1'b0;
      data_i  <= 32'h0;
    end else if (nxt_state == IDLE) begin
      valid_i <= 1'b0;
      data_i  <= 32'h0;
    end else if (nxt_state == BEAT1) begin
      valid_i <= 1'b1;
      data_i  <= 32'h1;
    end else if (update_en && (valid_i && ready_o)) begin
      valid_i <= 1'b1;
      data_i  <= data_i + 32'h1;
    end
  end

  BlockPipe u_BlockPipe (
      // Global clock and reset .clk
      .clk(clk),
      .rstn(rstn_dff[1]),
      // Slave interface
      .valid_i(valid_i),
      .data_i(data_i),
      .ready_o(ready_o),
      // Master interface
      .ready_i(ready_i),
      .valid_o(valid_o),
      .data_o (data_o)
  );

  // Dump wave 

  initial begin
    $fsdbDumpfile("BlockPipe.fsdb");
    $fsdbDumpvars();
  end

  // Auto compare
  int exp_queue[$];  //golden value
  int result[$];

  initial begin
    forever
    @(posedge clk) begin
      if (valid_i && ready_o) begin
        $display("--------------------------------");
        $display("The TX data is %h", data_i);
        exp_queue.push_back((data_i + 4) * 5);
      end else if (valid_o) begin
        $display("--------------------------------");
        $display("The RX data is %h", data_o);
        result.pus_back(data_o);
      end
    end
  end

  integer i;
  initial begin
    repeat (500) @(posedge clk);
    begin
      for (i = 0; i < 4; i = i + 1) begin
        if (exp_queue.pop_back == result.pop_back) begin
          $display("--------------------------------");
          $display("-----------Match--------------%d", i);
        end
      end
    end

    repeat (10)
    @(posedge clk) begin
      if (exp_queue[3] == result[3]) begin  //这里是因为有4次burst传输
        $display("--------------------------------");
        $display("Good Luck, simulate Pass !!!");
        $finish();
      end else begin

        $display("--------------------------------");
        $display("---Simulation fail !!!");
        $finish();
      end
    end
  end


endmodule
