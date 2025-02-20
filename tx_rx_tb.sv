module transmit_receive_unit_tb();
    reg clk;            // signals that are connected to the DUT
    reg rst;
    reg iocs;
    reg iorw;
    wire tbr;
    wire rda;
    reg [1:0] ioaddr;
    wire txd;
    reg [7:0] rate_tx_data;
    wire [7:0] data_received;
    reg enable;

    // instantiate the first DUT
    spart_transmitter tDUT (
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

    // instantiate the second DUT
    spart_receiver rDUT (
        .clk(clk),
        .rst(rst),
        .iocs(iocs),
        .iorw(iorw),
        .rda(rda),
        .ioaddr(ioaddr),
        .rxd(txd),
        .data_received(data_received),
        .enable(enable)
    );

    initial begin  // initialize all variables
        $display("Testing transmit unit and receive unit");
        clk = 0;
        rst = 1;
        iocs = 1;
        iorw = 1;
        ioaddr = 0;
        rate_tx_data = 8'hAA; // 8'b1010_1010 = 10'b11_0101_0100 = 10'h354
        enable = 0;

        @(posedge clk);
        rst = 0;
        ioaddr = 2'b00;

        $display("Testing transmitting first data byte of oscillating 0s and 1s (8'hAA)");
        iorw = 0;
        @(posedge clk);
        iorw = 1;

        while (tbr != 1) begin // wait until done
            pulse_enable();
        end

        if (data_received == 8'hAA) begin
            $display("\tTest passed");
        end else begin
            $display("\tTest failed, expected data_received = 8'hAA, actual data_received = 8'h%h", data_received);
        end

        $display("Testing transmitting second data byte of 8'b0011_1001");
        rate_tx_data = 8'b0011_1001; // 10_0111_0010 = 272
        iorw = 0;
        @(posedge clk);
        iorw = 1;
        @(posedge clk);

        while (tbr != 1) begin // wait until done
            pulse_enable();
        end

        if (data_received == 8'b0011_1001) begin
            $display("\tTest passed");
        end else begin
            $display("\tTest failed, expected data_received = 8'b0011_1001, actual data_received = 8'b%b", data_received);
        end

        $stop;
    end

    // task to pulse enable signal
    task pulse_enable;
        repeat (50) // wait multiple clock cycles
            @(posedge clk);
        enable = 1;  // set enable high
        @(posedge clk); // for 1 clock cycle
        enable = 0;  // reset enable
    endtask

    always #2 clk = ~clk;

endmodule
