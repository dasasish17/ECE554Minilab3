module spart_transmitter(
    input clk,
    input rst,
    input iocs,
    input iorw,
    output reg tbr,
    input [1:0] ioaddr,
    output txd,
    input [7:0] rate_tx_data,
    input enable
);

    reg [9:0] shift_reg;
    reg [3:0] bit_cnt;
    reg load, shift, set_tbr;
    
    localparam IDLE = 1'b0, TRANS = 1'b1;
    reg state, nxt_state;

    // Assign TX output to LSB of shift register
    assign txd = shift_reg[0];

    // State Machine for Transmission
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tbr <= 1'b0;
        end 
        else begin
            state <= nxt_state;
            tbr <= set_tbr;
        end
    end

    always @(*) begin
        // Default control signal values
        nxt_state = state;
        load = 1'b0;
        shift = 1'b0;
        set_tbr = 1'b0;

        case (state)
            IDLE: begin
                if (ioaddr == 2'b00 && !iorw) begin // Write signal received
                    load = 1'b1;
                    nxt_state = TRANS;
                end 
                else begin
                    set_tbr = 1'b1; // Transmitter ready
                end
            end
            TRANS: begin
                if (enable) begin
                    shift = 1'b1;
                    if (bit_cnt == 0) begin
                        nxt_state = IDLE;
                    end
                end
            end
        endcase
    end

    // Shift Register & Bit Counter Logic
    always @(posedge clk) begin
        if (load) begin
            // Load start bit (0), data, stop bit (1)
            shift_reg <= {1'b1, rate_tx_data, 1'b0};
            bit_cnt <= 9;
        end 
        else if (set_tbr) begin
            // Set txd high to indicate ready state
            shift_reg[0] <= 1'b1;
        end 
        else if (shift) begin
            // Shift bits out (transmit one bit at a time)
            shift_reg <= {1'b1, shift_reg[9:1]}; 
            bit_cnt <= bit_cnt - 1;
        end
    end

endmodule
