`timescale 1ns/1ps
module main_controller (
    input  wire clk,
    input  wire rstn,
    input  wire cfg_mode,
    input  wire selection_valid,
    input  wire currency_avail,
    input  wire dispense_valid, 
    output reg  dispense_enable
);
parameter IDLE     = 2'b00;
parameter SELECTED = 2'b01;
parameter CURRENCY = 2'b10;

reg [1:0] current_state, next_state;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin 
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

 // Next state logic
 always @(*) begin
    next_state      <= current_state;
    dispense_enable <= 0;
    if (cfg_mode) begin
        next_state  <= IDLE;  // FSM inactive during config
    end 
    else begin
        case (current_state)
            IDLE    : begin
                        if (selection_valid) begin
                            next_state     <= SELECTED; end
                      end
            SELECTED: begin
                        if (currency_avail) begin
                            next_state     <= CURRENCY; end
                      end
            CURRENCY: begin
	                    if (dispense_valid) begin
                            next_state      <= IDLE;
					        dispense_enable <= 0; 
				        end
				        else begin
                            next_state      <= CURRENCY; 
                            dispense_enable <= 1;
			            end
                     end
       endcase
    end
end

endmodule
