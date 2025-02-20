module baud_rate_generator( // inputs and outputs
    input clk,
    input rst,
    input iocs,
    input [1:0] ioaddr,
    input [7:0] rate_tx_data,
    output reg enable
);

reg [15:0] division_buffer;
reg [15:0] baud_rate_counter;

always @(posedge clk) begin
    if (iocs) begin
        if (rst) begin  // if reset, then enable
            division_buffer <= 1;
            baud_rate_counter <= 1;
        end 
        else if (ioaddr == 2'b11 && division_buffer[15:8] != rate_tx_data) begin
            division_buffer[15:8] <= rate_tx_data; // if high and high is not already set
            baud_rate_counter <= {rate_tx_data, division_buffer[7:0]} - 1;
        end 
        else if (ioaddr == 2'b10 && division_buffer[7:0] != rate_tx_data) begin
            division_buffer[7:0] <= rate_tx_data; // if low and low is not already set
            baud_rate_counter <= {division_buffer[15:8], rate_tx_data} - 1;
        end 
        else if (baud_rate_counter == 0) begin  // if 0, then reset
            baud_rate_counter <= division_buffer;
        end 
        else begin  // normally decrement
            baud_rate_counter <= baud_rate_counter - 1;
        end
    end
end

always @(posedge clk) begin
    if (iocs) begin  // never enable if iocs is low
        if (baud_rate_counter == 0) begin
            enable <= 1;  // enable when counter reaches 0
        end 
        else begin
            enable <= 0;
        end
    end
end

endmodule
