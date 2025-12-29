
/*
what is done in this module
    based on the availability of the item and amount given by user, this module decides what should be the output 
    i.e 1.whether item should be dispensed or not
        2.change that should be given to the user
parameters:-
    item_addr         : total 1024 items so 10 bits
    currency_width     : highest amount avaliable is 100 so 7 bits
    no_items_addr     : no of  each item available is 255 so 8 bits
    total_amount_width : total amount can be ( highest amount * total no.of one items possible= 100*255) so 15 bits
inputs    :-
    dispense_enable   : if item available =1, else 0
    item_selected     : item that is selected
    no_items_selected : no.of items given by user
    avail_items       : available no.of items in the vending machine
    item_price        : selected item price
    total_amount      : total amount given by the user
    invalid_amount    : invalid notes given by user that needed to be returned
outputs  :-
    item_dispense_valid    : if item is available to dispense=1 else o
    item_dispensed    : item that is dispensed
    change_dispensed  : change that is returned to the user*/

`timescale 1ns/1ps
module output_info#(
    parameter MAX_ITEMS           = 1024,
    parameter MAX_CURRENCY        = 100,
    parameter MAX_AVAIL_ITEMS     = 255,
    parameter MAX_COST            = 25500,

    parameter currency_width      = 8,     // can store item price up to 255
    parameter items_addr          = 10,    // item ID
    parameter no_items_addr       = 8,     // up to 255 items
    parameter total_amount_width  = 16     // can hold money sum up to 65535
)(
    input  wire                            clk,
    input  wire                            rstn,
    input  wire                            dispense_enable,
    input  wire [items_addr-1        : 0]  item_selected,
    input  wire [no_items_addr-1     : 0]  no_items_selected,
    input  wire [no_items_addr-1     : 0]  avail_items,
    input  wire [currency_width-1    : 0]  item_price,
    input  wire [total_amount_width-1: 0]  total_amount,

    output reg                             item_dispense_valid,
    output reg  [items_addr-1         : 0] item_dispensed,
    output reg  [total_amount_width-1 : 0] change_dispensed,
    output reg  [no_items_addr-1      : 0] no_items_dispensed
);
    // ZERO-EXTENSION BEFORE MULTIPLY 
    wire [total_amount_width-1:0] item_price_ext = {{(total_amount_width - currency_width){1'b0}}, item_price};
    wire [total_amount_width-1:0] no_items_ext   = {{(total_amount_width - no_items_addr){1'b0}}, no_items_selected};

    // Multiply in a width-safe way
    wire [total_amount_width-1:0] items_price = item_price_ext * no_items_ext;
    initial begin
         item_dispense_valid <= 1'b0;
         item_dispensed      <= 0;
         change_dispensed    <= 0;
         no_items_dispensed  <= 0;
    end

    // MAIN LOGIC
    always @(posedge clk or negedge rstn) begin
        item_dispense_valid <= 1'b0;
        item_dispensed      <= 0;
        change_dispensed    <= 0;
        no_items_dispensed  <= 0;
        if (!rstn) begin
            item_dispense_valid <= 1'b0;
            item_dispensed      <= 0;
            change_dispensed    <= 0;
            no_items_dispensed  <= 0;
        end
        else begin
            if (dispense_enable) begin
                if ((avail_items >= no_items_selected) && (total_amount >= items_price)) begin
                    item_dispense_valid <= 1'b1;
                    item_dispensed      <= item_selected;
                    no_items_dispensed  <= no_items_selected;
                    change_dispensed    <= total_amount - items_price;
                end
                else begin
                    item_dispense_valid <= 1'b0;
                    item_dispensed      <= 0;
                    no_items_dispensed  <= 0;
                    change_dispensed    <= total_amount;
                end
            end
        end
    end
endmodule
   /*else begin
     item_dispense_valid <= 0;
     if(dispense_enable) begin
         if( (avail_items >= 0) && (total_amount >= items_price) )  begin
             if(avail_items <= no_items_selected ) begin
                 for( i=0 ; i < avail_items; i=i+1) begin
                     item_dispense_valid   <= 1'b1;
                     item_dispensed   <= item_selected;
                     change_dispensed <= (total_amount-less_items_price)+ invalid_amount;
                 end
             end
             else begin
                 for( i=0 ; i < no_items_selected; i=i+1) begin
                     item_dispense_valid   <= 1'b1;
                     item_dispensed   <= item_selected;
                     change_dispensed <= (total_amount-items_price)+ invalid_amount;
                 end
             end    
         end
         else begin
             item_dispense_valid   <= 0;
             item_dispensed   <= 0;
             change_dispensed <= total_amount + invalid_amount ;
         end
     end
     else begin
         item_dispense_valid   <= 0;
         item_dispensed   <= 0;
         change_dispensed <= total_amount + invalid_amount;
     end
 end*/
