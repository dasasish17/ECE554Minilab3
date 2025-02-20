module spart( // inputs and outputs
    input clk,
    input rst,
    input iocs,
    input iorw,
    output rda,
    output tbr,
    input [1:0] ioaddr,
    inout [7:0] databus,
    output txd,
    input rxd
);

wire [7:0] rate_tx_data;  // wires to connect submodules
wire [7:0] data_received;

bus_interface bus_interface0( // instantiate the DUT
    .iocs(iocs),
    .iorw(iorw),
    .rda(rda),
    .tbr(tbr),
    .ioaddr(ioaddr),
    .databus(databus),
    .rate_tx_data(rate_tx_data),
    .data_received(data_received)
);

baud_rate_generator baud_rate_generator0( // instantiate the DUT
    .clk(clk),
    .rst(rst), // confirm? not shown in diagram, but we think it's needed
    .iocs(iocs),
    .ioaddr(ioaddr),
    .rate_tx_data(rate_tx_data),
    .enable(enable)
);

spart_transmitter transmit_unit0( // instantiate the DUT
    .clk(clk),
    .rst(rst),
    .iocs(iocs),
    .iorw(iorw),
    .tbr(tbr),
    .ioaddr(ioaddr),
    .txd(txd),
    .rate_tx_data(rate_tx_data),
    .enable(enable)
);

spart_receiver receive_unit0( // instantiate the DUT
    .clk(clk),
    .rst(rst),
    .iocs(iocs),
    .iorw(iorw),
    .rda(rda),
    .ioaddr(ioaddr),
    .rxd(rxd),
    .data_received(data_received),
    .enable(enable)
);

endmodule

