`timescale 1ns/1ps
module config_module #(
    parameter MAX_ITEMS          = 1024,
    parameter item_addr          =   10,
    parameter no_items_addr      =    8,
    parameter total_amount_width =   15
)(
    // APB config
    input  wire        pclk,
    input  wire        prstn,
    input  wire [15:0] paddr,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,
    output reg         pready,

    // Main logic
    input  wire                        cfg_mode,
    input  wire                        clk,
    input  wire                        rstn,
    input  wire [item_addr-1      : 0] item_id,
    output reg  [no_items_addr-1  : 0] avail_count,
    output reg  [no_items_addr-1  : 0] item_price,
    input  wire                        dispense_valid,
    input  wire  [no_items_addr-1 : 0] no_items_dispensed
);

    // Memories
    reg  [item_addr-1       : 0] no_of_items;
    reg  [total_amount_width:0] item_val      [0:MAX_ITEMS-1];
    reg  [no_items_addr-1   :0] avail_items   [0:MAX_ITEMS-1];
    reg  [no_items_addr-1   :0] disp_items    [0:MAX_ITEMS-1];

    // Address decoding
    wire is_main_cfg = (paddr == 15'h0000);
    wire is_item_cfg = (paddr >= 15'h0004);

    wire [item_addr-1:0] addr_offset =
        (paddr - 15'h0004) >> 2;

    integer i;

    // -------------------------------------------------------------
    //  APB DOMAIN - CAPTURE WRITE COMMAND (NO ARRAY WRITES HERE!)
    // -------------------------------------------------------------

    reg        apb_wr_en;
    reg [item_addr-1:0] apb_wr_addr;
    reg [15:0]          apb_wr_item_val;
    reg [7:0]           apb_wr_avail_items;

    always @(posedge pclk or negedge prstn) begin
        if (!prstn) begin
            pready               <= 0;
            prdata               <= 0;
            no_of_items          <= 0;

            apb_wr_en            <= 0;
            apb_wr_addr          <= 0;
            apb_wr_item_val      <= 0;
            apb_wr_avail_items   <= 0;

        end else begin
            pready <= 0;
            apb_wr_en <= 0; // default

            if (cfg_mode && psel && penable) begin
                pready <= 1;

                if (pwrite) begin
                    // WRITE
                    if (is_main_cfg) begin
                        no_of_items <= pwdata[item_addr-1:0];
                    end else if (addr_offset < MAX_ITEMS) begin
                        // Capture write command (no direct write!)
                        apb_wr_en          <= 1;
                        apb_wr_addr        <= addr_offset;
                        apb_wr_item_val    <= pwdata[15:0];
                        apb_wr_avail_items <= pwdata[23:16];
                    end
                end else begin
                    // READ
                    if (is_main_cfg) begin
                        prdata <= {{(32-item_addr){1'b0}}, no_of_items};
                    end else if (addr_offset < MAX_ITEMS) begin
                        prdata <= {
                            disp_items[addr_offset],
                            avail_items[addr_offset],
                            item_val[addr_offset]
                        };
                    end else begin
                        prdata <= 32'd0;
                    end
                end
            end
        end
    end

    // -----------------------------------------------------------------
    //  CDC - SYNCHRONIZE APB WRITE INTO CLK DOMAIN
    // -----------------------------------------------------------------

    // 2-FF sync for write enable
    reg apb_wr_en_sync1, apb_wr_en_sync2;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            apb_wr_en_sync1 <= 0;
            apb_wr_en_sync2 <= 0;
        end else begin
            apb_wr_en_sync1 <= apb_wr_en;
            apb_wr_en_sync2 <= apb_wr_en_sync1;
        end
    end

    wire wr_cmd_valid = apb_wr_en_sync1 & ~apb_wr_en_sync2;

    // Sync write data (they change only when wr_cmd_valid pulses)
    reg [item_addr-1:0] apb_wr_addr_sync;
    reg [15:0]          apb_wr_item_val_sync;
    reg [7:0]           apb_wr_avail_items_sync;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            apb_wr_addr_sync        <= 0;
            apb_wr_item_val_sync    <= 0;
            apb_wr_avail_items_sync <= 0;
        end else if (wr_cmd_valid) begin
            apb_wr_addr_sync        <= apb_wr_addr;
            apb_wr_item_val_sync    <= apb_wr_item_val;
            apb_wr_avail_items_sync <= apb_wr_avail_items;
        end
    end

    // -------------------------------------------------------------
    //  MAIN CLK DOMAIN - ALL ARRAY WRITES HAPPEN HERE ONLY
    // -------------------------------------------------------------

    reg [7:0]  avail_items_sync;
    reg [15:0] item_val_sync;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            avail_items_sync <= 0;
            item_val_sync    <= 0;
            avail_count      <= 0;
            item_price       <= 0;

            for (i = 0; i < MAX_ITEMS; i = i + 1) begin
                item_val[i]    <= 0;
                avail_items[i] <= 0;
                disp_items[i]  <= 0;
            end

        end else begin

            // APPLY APB WRITE COMMAND
           // if (wr_cmd_valid) begin
                item_val   [apb_wr_addr_sync] <= apb_wr_item_val_sync;
                avail_items[apb_wr_addr_sync] <= apb_wr_avail_items_sync;
                disp_items [apb_wr_addr_sync] <= 0;
           // end

            // READ PATH
            avail_items_sync <= avail_items[item_id];
            item_val_sync    <= item_val[item_id];
            avail_count      <= avail_items_sync;
            item_price       <= item_val_sync;

            // DISPENSE LOGIC
            if (dispense_valid) begin
                avail_items[item_id] <= avail_items_sync - no_items_dispensed;
                disp_items [item_id] <= disp_items[item_id] + no_items_dispensed;
            end
        end
    end

endmodule

/*module config_module #(
    parameter MAX_ITEMS          = 1024,
    parameter item_addr          =   10,
    parameter no_items_addr      =    8,
    parameter total_amount_width =   15
)(
    //apb config 
    input  wire        pclk,
    input  wire        prstn,
    input  wire [15:0] paddr,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,
    output reg         pready,

    input  wire                        cfg_mode,
    input  wire                        clk,
    input  wire                        rstn,
    input  wire [item_addr-1      : 0] item_id,
    output reg  [no_items_addr-1  : 0] avail_count,
    output reg  [no_items_addr-1  : 0] item_price, 
    input  wire                        dispense_valid,
    input  wire  [no_items_addr-1 : 0] no_items_dispensed 
);
    reg  [item_addr-1       : 0] no_of_items;
    reg  [total_amount_width: 0] item_val      [0 : MAX_ITEMS-1];
    reg  [ no_items_addr-1  : 0] avail_items   [0 : MAX_ITEMS-1];
    reg  [ no_items_addr-1  : 0] disp_items    [0 : MAX_ITEMS-1];
    wire [item_addr-1       : 0] addr_offset;
    wire is_main_cfg   = (paddr == 15'h0000);
    wire is_item_cfg   = (paddr >= 15'h0004);
    

    assign addr_offset = (paddr - 15'h0004) >> 2;

    integer i;

    always @(posedge pclk or negedge prstn) begin
        if (!prstn) begin
            pready <= 0;
            prdata <= 0;
            no_of_items <= 0;
            for (i = 0; i < MAX_ITEMS; i = i + 1) begin
                item_val[i]    <= 0;
                avail_items[i] <= 0;
                disp_items[i]  <= 0;
            end
        end 
        else if (cfg_mode && psel && penable) begin
            pready <= 1;
            if (pwrite) begin
                if (is_main_cfg) begin
                    no_of_items <= pwdata[item_addr-1:0];
                end else if (addr_offset < MAX_ITEMS) begin
                    item_val   [addr_offset] <= pwdata[15:0];
                    avail_items[addr_offset] <= pwdata[23:16];
                    disp_items [addr_offset] <= 0;
                end
            end 
            else begin
                if (is_main_cfg) begin
                    prdata <= {{(32-item_addr){1'b0}}, no_of_items };
                end else if (addr_offset < MAX_ITEMS) begin
                    prdata <= { disp_items[addr_offset], avail_items[addr_offset], item_val[addr_offset] };
                end else begin
                    prdata <= 32'd0;
                end
            end
        end 
        else begin
            pready <= 0;
        end
    end

    reg [7:0]  avail_items_sync;
    reg [15:0] item_val_sync;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            avail_items_sync <= 0;
            item_val_sync    <= 0;
            avail_count      <= 0;
            item_price       <= 0;
        end else begin
            avail_items_sync <= avail_items[item_id];
            item_val_sync    <= item_val   [item_id];
            avail_count      <= avail_items_sync;
            item_price       <= item_val_sync;
            if(dispense_valid) begin
                avail_items[item_id] <= avail_items_sync    - no_items_dispensed;
                disp_items [item_id] <= disp_items[item_id] + no_items_dispensed;
            end
        end
    end
endmodule*/
