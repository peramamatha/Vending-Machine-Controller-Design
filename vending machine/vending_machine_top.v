module vending_machine_top #(
    parameter MAX_ITEMS          = 1024,
    parameter item_addr          =   10,
    parameter no_items_addr      =    8,
    parameter total_amount_width =   15,
    parameter currency_width     =   8
)(
    input  wire                            clk,
    input  wire                            rstn,
    input  wire                            cfg_mode,

    // Item Selection Interface
    input  wire [item_addr-1          : 0] item_select,
    input  wire                            item_select_valid,
    input  wire [no_items_addr-1      : 0] no_items_select,

    // Currency Interface
    input  wire [currency_width-1     : 0] currency_in,
    input  wire                            currency_valid,

    // APB Config Interface
    input  wire                            pclk,
    input  wire                            prstn,
    input  wire [15:0]                     paddr,
    input  wire                            psel,
    input  wire                            penable,
    input  wire                            pwrite,
    input  wire [31:0]                     pwdata,
    output wire [31:0]                     prdata,
    output wire                            pready,

    // Output
    output wire                            dispense_valid,
    output wire [item_addr-1          : 0] item_dispensed,
    output wire [total_amount_width-1 : 0] change_dispensed,
    output wire [no_items_addr-1      : 0] no_items_dispensed
);

//intermediate signals

wire                              select_valid_pulse;
wire                              currency_valid_pulse;
wire  [item_addr-1          : 0]  item_selected;
wire  [no_items_addr-1      : 0]  no_items_selected;
wire                              selection_done;
wire                              currency_done;
wire  [ total_amount_width-1: 0 ] total_amount; 
wire  [no_items_addr-1      : 0 ] avail_count;
wire  [currency_width-1     : 0 ] item_price;
wire                              dispense_enable;


 // CDC Sync Modules
pulse_sync u_currency_sync (
    .clk_dst           (clk                 ),
    .rstn              (rstn                ),
    .pulse_src         (currency_valid      ),
    .pulse_dst         (currency_valid_pulse)
);

pulse_sync u_item_sync (
    .clk_dst           (clk                 ),
    .rstn              (rstn                ),
    .pulse_src         (item_select_valid   ),
    .pulse_dst         (select_valid_pulse  )
);

//item_selection_interface
item_selection #(
    .item_addr         (item_addr           ),
    .no_items_addr     (no_items_addr       )
) u_item_selection (
    .clk               ( clk                ),
    .rstn              (rstn                ),
    .select_valid_pulse(select_valid_pulse  ),
    .item_select       (item_select         ),
    .no_items_select   (no_items_select     ),
    .dispense_valid    (dispense_valid      ),
    .item_selected     (item_selected       ),
    .no_items_selected (no_items_selected   ),
    .selection_done    (selection_done      )
 );
 
 //currency_interface
currency_input #(
    .currency_width      (currency_width     ),
    .total_amount_width  (total_amount_width )
 ) u_currency_input (
    .clk                 (clk                ),
    .rstn                (rstn               ),
    .currency_in         (currency_in        ),
    .currency_valid_pulse(currency_valid     ),
    .dispense_valid      (dispense_valid     ),
    .currency_done       (currency_done      ),
    .total_amount        (total_amount       )
  //.invalid_amount      (invalid_amount     )
);

//configuration module
config_module #(
    .MAX_ITEMS           (MAX_ITEMS          ),
    .item_addr           (item_addr          ),
    .no_items_addr       (no_items_addr      ),
    .total_amount_width  (total_amount_width )
)u_config_module (
    // APB Domain
    .pclk                (pclk               ),
    .prstn               (prstn              ),
    .paddr               (paddr              ),
    .psel                (psel               ),
    .penable             (penable            ),
    .pwrite              (pwrite             ),
    .pwdata              (pwdata             ),
    .prdata              (prdata             ),
    .pready              (pready             ),

    // Main / Normal Domain
    .cfg_mode            (cfg_mode           ),
    .clk                 (clk                ),
    .rstn                (rstn               ),
    .item_id             (item_selected      ),
    .avail_count         (avail_count        ),
    .item_price          (item_price         ),
  //.dispense_enable     (dispense_enable    ),
    .dispense_valid      (dispense_valid     ),
    .no_items_dispensed  (no_items_dispensed )
);

//output logic
output_info#(
    .items_addr         (item_addr           ),
    .currency_width    (currency_width       ),
    .no_items_addr     (no_items_addr        ),
    .total_amount_width(total_amount_width   )

) u_output_info(
    .clk               (clk                  ),
    .rstn              (rstn                 ),
    .dispense_enable   (dispense_enable      ),
    .item_selected     (item_selected        ),
    .no_items_selected (no_items_selected    ),
    .avail_items       (avail_count          ),
    .item_price        (item_price           ),
    .total_amount      (total_amount         ),
  //.invalid_amount    (invalid_amount       ),
  //.selection_done    (selection_done       ),
  //.currency_done     (currency_done        ),
    .item_dispense_valid(dispense_valid      ),
    .item_dispensed    (item_dispensed       ),
    .change_dispensed  (change_dispensed     ),
    .no_items_dispensed(no_items_dispensed   )
 );

//main_controller

main_controller u_main_controller(
    .clk                (clk                 ),
    .rstn               (rstn                ),
    .cfg_mode           (cfg_mode            ),
    .selection_valid    (selection_done      ),
    .currency_avail     (currency_done       ),
    .dispense_valid     (dispense_valid      ), 
    .dispense_enable    (dispense_enable     )
);

endmodule
