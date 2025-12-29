`timescale 1ns/1ps

module vending_machine_top_tb;

localparam MAX_ITEMS = 'd32;
localparam MAX_NOTE_VAL = 'd100;
localparam currency_width = 'd8;
localparam item_addr      = 'd10;

reg clk;
reg rstn;
reg        pclk;
reg [15:0] paddr;
reg        prstn;
reg [31:0] pwdata;
reg [31:0] prdata;
reg        pwrite;
reg        pready;
reg        psel;
reg        penable;
reg        cfg_mode;
reg currency_valid;
reg [currency_width-1 : 0] currency_value;
reg item_select_valid;
reg [item_addr-1 : 0] item_select;
reg [7:0] no_of_items;

// Output interface
wire item_dispense_valid;
wire [item_addr-1 : 0] item_dispense;
wire [7:0] no_items_dispensed;
wire [14:0] change_dispensed;

reg debug_en;
// string test_name;   // ❌ Vivado can't trace dynamic strings
reg [1023:0] test_name;  // ✅ Static string alternative (Vivado-compatible)

//================ DUT Instantiation (unchanged) =================//
vending_machine_top #(
  .MAX_ITEMS (MAX_ITEMS)
  // .MAX_NOTE_VAL(MAX_NOTE_VAL)
) dut (
  //// General interface
  .clk (clk),
  .rstn(rstn),
  .cfg_mode(cfg_mode),

  //// Item Select Interface
  .item_select_valid(item_select_valid),
  .item_select(item_select),
  .no_items_select(no_of_items),

  //// Coin or Note interface
  .currency_in(currency_value),
  .currency_valid(currency_valid),

  //// APB Interface
  .pclk                (pclk),
  .prstn               (prstn),
  .paddr               (paddr),
  .psel                (psel),
  .penable             (penable),
  .pwrite              (pwrite),
  .pwdata              (pwdata),
  .prdata              (prdata),
  .pready              (pready),

  //// Output interface
  .dispense_valid(item_dispense_valid),
  .item_dispensed(item_dispense),
  .change_dispensed(change_dispensed),
  .no_items_dispensed(no_items_dispensed)
);

//===============================================================//
// Initialization
//===============================================================//
initial begin
  clk         = 'h0;
  rstn        = 1'b1;
  pclk        = 'h0;
  prstn       = 1'b1;
  paddr       = 'h0;
  pwdata      = 'h0;
  pwrite      = 'h0;
  psel        = 'h0;
  currency_valid     = 'h0;
  currency_value    = 'hFFF;
  item_select_valid  = 'h0;
  item_select   = 'hFFFF;
  no_of_items   = 'h1;
end

//===============================================================//
// Clock Generation
//===============================================================//
initial forever #5 clk = ~clk;
initial forever #5 pclk = ~pclk;

//===============================================================//
// Reset Generation
//===============================================================//
initial begin
  rstn = 1'b1;
  prstn = 1'b1;
  #1ns;
  rstn = 1'b0;
  prstn = 1'b0;
  #10ns;
  rstn = 1'b1;
  prstn = 1'b1;
end

//===============================================================//
// Plusargs (Vivado-safe version)
//===============================================================//
initial begin
  debug_en = 0;
  test_name = "";

  if ($test$plusargs("DEBUG")) begin
    $display("[%0t] DEBUG mode enabled", $time);
    debug_en = 1;
  end

  if ($value$plusargs("TEST_NAME=%s", test_name)) begin
    $display("[%0t] Test name = %0s", $time, test_name);
  end else begin
    $display("[%0t] No TEST_NAME provided (+TEST_NAME=<name>)", $time);
  end
end

//===============================================================//
// Dump file for GTKWave / EPWave
//===============================================================//
initial begin
  $dumpfile("dump.vcd");
  $dumpvars(0, vending_machine_top_tb);
end

//===============================================================//
// Test Selection
//===============================================================//
initial begin
  $display("testname=%0s", test_name);
  #100ns;
  case (test_name)
    "write_read_test": write_read_test();
    "directed_test"  : directed_test();
    "random_test"    : random_test();
    default: begin
      $display("No valid TEST_NAME specified. Running default: directed_test()");
      directed_test();
    end
  endcase
  $finish;
end

//===============================================================//
// APB Write Task
//===============================================================//
task apb_write(input [15:0] addr, input [31:0] data);
begin
  @(negedge clk);
  paddr  = 'h0;
  psel   = 1'b0;
  pwrite = 1'b0;
  pwdata = 'h0;
  penable = 1'b1;
  cfg_mode = 1'b1;
  @(negedge clk);
  paddr  = addr;
  psel   = 1'b1;
  pwrite = 1'b1;
  pwdata = data;
  @(negedge clk);
  paddr  = 'h0;
  psel   = 1'b0;
  pwrite = 1'b0;
  pwdata = 'h0;
  penable = 1'b0;
  cfg_mode = 1'b0;
  @(negedge clk);
end
endtask

//===============================================================//
// APB Read Task
//===============================================================//
task apb_read(input [15:0] addr, output [31:0] rd_data, input [31:0] chk_data=0, input chk=0);
begin
  @(negedge clk);
  paddr  = 'h0;
  psel   = 'h0;
  pwrite = 'h0;
  penable = 1'b1;
  cfg_mode = 1'b1;
  @(negedge clk);
  paddr  = addr;
  psel   = 1'b1;
  pwrite = 'h0;
  pwdata = 'h0;
  @(negedge clk);
  rd_data = prdata;
  if (chk && (prdata !== chk_data)) begin
    $error("Expected Data = %0x Actual Data = %0x", chk_data, prdata);
  end else if (debug_en) begin
    $display("Read Data = %0x", prdata);
  end
  paddr  = 'h0;
  psel   = 'h0;
  pwrite = 'h0;
  pwdata = 'h0;
  penable = 1'b0;
  cfg_mode = 1'b0;
  @(negedge clk);
end
endtask

//===============================================================//
// Item Configuration Tasks
//===============================================================//
task program_item_cfg(input [item_addr-1:0] item_no, input [15:0] item_value, input [7:0] item_available);
begin
  apb_write((16'h0004 + (4*item_no)), {8'h0, item_available, item_value});
end
endtask

task read_item_cfg(input [item_addr-1:0] item_no, input [15:0] item_value, input [7:0] item_available, output rd_data);
begin
  apb_read((16'h0004 + (4*item_no)), rd_data, {8'h0, item_available, item_value});
end
endtask

//===============================================================//
// Item Set/Reset Task
//===============================================================//
task set_rst_item(input [item_addr-1:0] item_no, input set_rst, input [7:0] no_items);
begin
  @(negedge clk);
  if (set_rst) begin
    item_select_valid = 1'b1;
    item_select  = item_no;
    no_of_items  = no_items;
    $display("Set Items: %0d ", no_items);
  end else begin
    item_select_valid = 1'b0;
    item_select  = 'hFFFF;
    no_of_items  = 'd1;
  end
  @(negedge clk);
end
endtask

//===============================================================//
// Currency Input Task
//===============================================================//
task send_note(input [15:0] val);
begin
  $display("Driving Note Interface: %0d", val);
  @(negedge clk);
  currency_valid = 1'b1;
  currency_value = val;
  @(negedge clk);
  currency_valid = 0;
  currency_value = 8'hFF;
  @(negedge clk);
end
endtask

//===============================================================//
// Total Money Input Task
//===============================================================//
task input_total_money(input [15:0] total_value);
reg [15:0] remaining_value;
begin
  remaining_value = total_value;
  $display("Input Total Money: %0d", remaining_value);
  while (remaining_value > 0) begin
    if (remaining_value >= 20) begin
      send_note(20); remaining_value -= 20;
    end else if (remaining_value >= 10) begin
      send_note(10); remaining_value -= 10;
    end else if (remaining_value >= 5) begin
      send_note(5); remaining_value -= 5;
    end else if (remaining_value >= 2) begin
      send_note(2); remaining_value -= 2;
    end else if (remaining_value >= 1) begin
      send_note(1); remaining_value -= 1;
    end
  end
end
endtask

//===============================================================//
// Item Dispense Task
//===============================================================//
task get_item(input [item_addr-1:0] item_sel, input [7:0] no_of_items, input [15:0] item_value, input [7:0] change=0);
begin
  $display("********************************"); 
  $display(" Item No: %0d | Value: %0d | Count: %0d | Total: %0d | Change: %0d",
           item_sel, item_value, no_of_items, (no_of_items*item_value), change);
  set_rst_item(item_sel, 1, no_of_items);
  fork
    begin
      input_total_money((no_of_items*item_value) + change);
    end
    begin
      forever begin
        @(negedge clk);
        if (item_dispense_valid) begin
          $display("Output: Item %0d Dispensed | Count: %0d | Change: %0d",
                   item_dispense, no_items_dispensed, change_dispensed);
        end
      end
    end
  join_any
  disable fork;
  set_rst_item(item_sel, 0, 1);
  $display("---------------------------------\n");
end
endtask

//===============================================================//
// Testcases
//===============================================================//
task write_read_test();
reg [31:0] rd_data;
begin
  $display("Running write_read_test");
  apb_write('h0, 'habcd);
  for (int i=0; i<MAX_ITEMS-1; i++) begin
    apb_write((16'h1000 + i), (16'h2000 + i));
  end
  apb_read('h0, rd_data, 'habcd, 1'b1);
  for (int i=0; i<MAX_ITEMS-1; i++) begin
    apb_read((16'h1000 + i), rd_data, (16'h2000 + i), 1'b1);
  end
end
endtask

task directed_test();
reg [15:0] item_val[8];
reg [7:0]  item_avail[8];
reg [7:0]  item_no_of_items[8];
begin
  $display("Running directed_test");
  item_val[0]=11; item_val[1]=22; item_val[2]=35; item_val[3]=55;
  item_val[4]=51; item_val[5]=48; item_val[6]=36; item_val[7]=8;
  
  item_avail[0]=13; item_avail[1]=17; item_avail[2]=19; item_avail[3]=12;
  item_avail[4]=21; item_avail[5]=19; item_avail[6]=30; item_avail[7]=15;
  
  item_no_of_items[0]=1; item_no_of_items[1]=2; item_no_of_items[2]=3;
  item_no_of_items[3]=1; item_no_of_items[4]=7; item_no_of_items[5]=2;
  item_no_of_items[6]=1; item_no_of_items[7]=8;

  for (int i=0; i<8; i++)
    program_item_cfg(i, item_val[i], item_avail[i]);

  get_item(1, item_no_of_items[1], item_val[1], 1);
  get_item(5, item_no_of_items[5], item_val[5], 1);
  get_item(3, item_no_of_items[3], item_val[3], 0);
  get_item(4, item_no_of_items[4], item_val[4], 0);
  get_item(7, item_no_of_items[7], item_val[7], 1);
  get_item(0, item_no_of_items[0], item_val[0], 1);
  get_item(2, item_no_of_items[2], item_val[2], 5);
  get_item(6, item_no_of_items[6], item_val[6], 1);

  repeat(10) @(negedge clk);
end
endtask

task random_test();
begin
  $display("Running random_test (placeholder)");
end
endtask

endmodule
