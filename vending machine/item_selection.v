`timescale 1ns/1ps
/* what is happening in this module :-
    take inputs like item selection, how many of the selectem item needed and after the process it gives selection done as 1          
parameters :-
    item_addr          : total 1024 items so 10 bits
    no_items_addr      : no of  each item available is 255 so 8 bits   
inputs     :-
    clk                : system clk
    rstn               : system reset
    select_valid_pulse : it gives 1 if item selection pulse is synchronised with design clk pulse
    item_select        : item selected by user
    no_items_select    : no.of items selected by user 
    dispense_valid     : it item is dispensed=1 ,else 0 
outputs    :-
    item_selected      : item selected by user
    no_items_selected  : no.of items selected by user 
    selection_done     : if item is selected it gives 1, else 0
*/
module item_selection#(
    parameter item_addr     = 10,
    parameter no_items_addr =  8
    )(
    input  wire                       clk,
    input  wire                       rstn,
    input  wire                       select_valid_pulse,
    input  wire [item_addr-1    : 0]  item_select,
    input  wire [no_items_addr-1: 0]  no_items_select,
    input  wire                       dispense_valid,
    output reg  [item_addr-1    : 0]  item_selected,
    output reg  [no_items_addr-1: 0]  no_items_selected,
    output reg                        selection_done
    );
    initial begin
        item_selected     <= 0;
        no_items_selected <= 0;
        selection_done    <= 0;
    end
    always@(posedge clk or negedge rstn ) begin
        if(!rstn) begin
            item_selected     <= 0;
            no_items_selected <= 0;
            selection_done    <= 0;
        end 
        else begin
            if(select_valid_pulse) begin
                item_selected     <= item_select;
                no_items_selected <= no_items_select;
                selection_done    <= 1'b1;
            end
            else if(dispense_valid) begin
                item_selected     <= 0;
                no_items_selected <= 0;
                selection_done    <= 0;
            end
            else begin
                selection_done    <= 0;
            end 
        end
    end 
endmodule
