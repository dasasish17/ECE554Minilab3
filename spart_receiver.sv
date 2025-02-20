module spart_receiver(
    input clk,
    input rst,
    input iocs,
    input iorw,
    output reg rda,
    input [1:0] ioaddr,
    input rxd,
    output reg [7:0] data_received,
    input enable
);

    reg [9:0] shift_reg;  // Holds received data
    reg [3:0] bit_cnt;    // Counts received bits
    reg load, shift, set_rda;

    // UART states
    localparam IDLE = 2'b00, RECEIVE = 2'b01, DONE = 2'b10;
    reg [1:0] state, nxt_state;

    // Shift Register and Bit Counter Logic
    always @(posedge clk) begin
        if (load) begin
            // Load the bit counter to 9 bits (1 start bit, 8 data bits, 1 stop bit)
            bit_cnt <= 9;
        end 
        else if (shift) begin
            // Shift received bits in
            bit_cnt <= bit_cnt - 1;
            shift_reg <= {rxd, shift_reg[9:1]};
        end 
        else if (set_rda) begin
            // Store received data (excluding start and stop bits)
            data_received <= shift_reg[8:1];
        end
    end

    // FSM State Transition Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            rda <= 1'b0;
        end 
        else begin
            state <= nxt_state;
            rda <= set_rda;
        end
    end

    // Next State Logic
    always @(*) begin
        // Default control values
        nxt_state = state;
        load = 1'b0;
        shift = 1'b0;
        set_rda = 1'b0;

        case (state)
            IDLE: begin
                // Wait for a start bit (rxd == 0) to begin reception
                if (ioaddr == 2'b00 && iorw && !rxd) begin
                    load = 1'b1;
                    nxt_state = RECEIVE;
                end
            end
            RECEIVE: begin
                // Shift in bits if enabled
                if (enable) begin
                    shift = 1'b1;
                    if (bit_cnt == 0) begin
                        nxt_state = DONE;
                    end
                end
            end
            DONE: begin
                // Data reception complete, hold data until read
                set_rda = 1'b1;
                nxt_state = DONE;

                // Wait for a read signal before going back to IDLE
                if (ioaddr == 2'b00 && !iorw) begin
                    nxt_state = IDLE;
                end
            end
        endcase
    end

endmodule
