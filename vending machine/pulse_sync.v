/*
 this modulse is used to synchronise the intermediate pulses with system pulse
*/
module pulse_sync (
    input  wire clk_dst,
    input  wire rstn,
    input  wire pulse_src,
    output reg  pulse_dst
);
    reg sync_0, sync_1;
    reg sync_1_d;

    always @(posedge clk_dst or negedge rstn) begin
        if (!rstn) begin
            sync_0     <= 0;
            sync_1     <= 0;
            sync_1_d   <= 0;
            pulse_dst  <= 0;
        end else begin
            sync_0    <= pulse_src;
            sync_1    <= sync_0;
            sync_1_d  <= sync_1;
            pulse_dst <= sync_1 & ~sync_1_d;
        end
    end
endmodule
