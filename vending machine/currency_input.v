`timescale 1ns/1ps
/*
what is happening in this module:-
    currency is taken from the user and verifying whether it is valid or not and added to the total amount
parameters :-
    currency_width     : highest amount avaliable is 100 so 7 bits
    total_amount_width : total amount can be ( highest amount * total no.of one items possible= 100*255) so 15 bits
inputs     :-
    clk                  ; system clk
    rstn                 : system rst
    currency_in          : currency given by user
    currency_valid_pulse : it gives 1 if currency pulse is synchronised with over all pulse
    dispense_valid       : it item is dispensed=1 , else 0
outputs    :-
    currency_valid       : if given currency value is valid =1 , else 0
    total_amount         : total valid currency given by user
    invalid_amount       : total invalid currency given by user
*/
module currency_input #(
    parameter currency_width     =  8, 
    parameter total_amount_width = 15   
)(
    input  wire                             clk,
    input  wire                             rstn,
    input  wire [ currency_width-1    : 0 ] currency_in,
    input  wire                             currency_valid_pulse,
    input  wire                             dispense_valid,
    output reg                              currency_done,
    output reg  [ total_amount_width-1: 0 ] total_amount
    //output reg  [ total_amount_width-1: 0 ] invalid_amount
);

initial begin
    currency_done  <= 0;
    total_amount   <= 0;
end
always@(posedge clk or negedge rstn) begin
    if(!rstn) begin
        currency_done  <= 0;
        total_amount   <= 0;
        //invalid_amount <= 0;
    end
    else begin
       if (dispense_valid) begin
                total_amount   <= 0;
                currency_done  <= 0;
                //invalid_amount <= 0;
        end
       else if(currency_valid_pulse) begin
          /* if((currency_in == 7'd5)  || (currency_in == 7'd10) || (currency_in == 7'd15) || (currency_in == 7'd20) ||
               (currency_in == 7'd50) ||  (currency_in == 7'd100) ) begin*/
                total_amount   <= total_amount + currency_in;
                currency_done <= 1'b1;
           /* end
            else begin
                invalid_amount <= invalid_amount + currency_in;
                currency_done <= 1'b0;
            end*/
        end
        else begin
            total_amount   <= total_amount;
            currency_done  <= 1'b0;
        end
    end
end    
endmodule
