module bus_interface(
    input iocs,
    input iorw,
    input rda,
    input tbr,
    input [1:0] ioaddr,
    inout [7:0] databus,
    output reg [7:0] rate_tx_data,
    input [7:0] data_received
);

always @(*) begin
    rate_tx_data <= databus;
end

wire [7:0] databus_out;
assign databus_out = (ioaddr[0]) ? {6'b000000, tbr, rda} : data_received;  // processor reading/SPART response
assign databus = (!iorw || ioaddr[1]) ? 8'hzz : databus_out;  // high impedance is required

endmodule
