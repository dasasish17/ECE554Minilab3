///////////////////////////////////////////////
// inputs and outputs
///////////////////////////////////////////////
module driver(
    input clk,
    input rst,
    input [1:0] br_cfg,
    output iocs,
    output iorw,
    input rda,
    input tbr,
    output reg [1:0] ioaddr,
    inout [7:0] databus
);
    assign iocs = 1;
    reg iorw_reg;
    assign iorw = iorw_reg; // set to reg so that it can be set and keep its prototype

    reg [7:0] inout_data;
    reg [7:0] held_data;
    reg update_baud, start_sending_baud_hi, start_sending_baud_lo,
        start_receiving, start_transmitting, receiving, transmitting;

    reg [2:0] old_br_cfg;
    // localparam BAUD_4800  = 16'h0514; // division for 4800  = 100000000/(16*4800)  - 1 = d1300 = h0514
    // localparam BAUD_9600  = 16'h028A; // division for 9600  = 100000000/(16*9600)  - 1 = d650  = h028A
    // localparam BAUD_19200 = 16'h0145; // division for 19200 = 100000000/(16*19200) - 1 = d325  = h0145
    // localparam BAUD_38400 = 16'h00A2; // division for 38400 = 100000000/(16*38400) - 1 = d162  = h00A2
    localparam BAUD_4800  = 16'h028b; // division for 4800  = 50000000/(16*4800)  - 1 = d1300 = h0514
    localparam BAUD_9600  = 16'h0146; // division for 9600  = 50000000/(16*9600)  - 1 = d650  = h028A
    localparam BAUD_19200 = 16'h00a8; // division for 19200 = 50000000/(16*19200) - 1 = d325  = h0145
    localparam BAUD_38400 = 16'h0052; // division for 38400 = 50000000/(16*38400) - 1 = d162  = h00A2
    reg [15:0] new_baud;

    localparam IDLE   = 3'b000,
               BAUDHI = 3'b001,
               BAUDLO = 3'b010,
               RECV   = 3'b011,
               TRANS  = 3'b100;

    reg [2:0] state, nxt_state;

    // handle state transitions of the FSM
    always @(posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            old_br_cfg  <= 3'b100;
        end else begin
            //state <= nxt_state;

            if (update_baud) begin
                old_br_cfg <= {1'b0, br_cfg};
                case (br_cfg)
                    2'b00: new_baud <= BAUD_4800;
                    2'b10: new_baud <= BAUD_19200;
                    2'b11: new_baud <= BAUD_38400;
                    default: new_baud <= BAUD_9600;
                endcase
            end else if (start_sending_baud_hi) begin
                inout_data <= new_baud[15:8];
                ioaddr <= 2'b11;
            end else if (start_sending_baud_lo) begin
                inout_data <= new_baud[7:0];
                ioaddr <= 2'b10;
            end else if (start_receiving) begin
                inout_data <= databus;
            end else if (start_transmitting) begin
                inout_data <= held_data;
            end else if (receiving) begin
                ioaddr <= 2'b00;
                iorw_reg <=1;
            end else if (transmitting) begin
                ioaddr <= 2'b00;
                iorw_reg <= 0;
            end else begin
                ioaddr <= 2'b01;
            end
            state <= nxt_state;
        end
    end

    assign databus = (state == IDLE || state == RECV) ? 8'bzz : inout_data;

    always @(*) begin
        // set defaults
        nxt_state = IDLE;
        update_baud = 0;
        start_sending_baud_hi = 0;
        start_sending_baud_lo = 0;
        start_receiving = 0;
        receiving = 0;
        start_transmitting = 0;
        transmitting = 0;

        case (state)
            IDLE: begin
                // send baud rate if uninitialized
                if (old_br_cfg[2] || br_cfg != old_br_cfg[1:0]) begin
                    update_baud = 1;
                    nxt_state = BAUDHI;
                end else if (rda) begin
                    // receive data if data is ready to be received
                    start_receiving = 1;
                    nxt_state = RECV;
                end
            end

            BAUDHI: begin
                // send baud rate high
                start_sending_baud_hi = 1;
                nxt_state = BAUDLO;
            end

            BAUDLO: begin
                // send baud rate low
                start_sending_baud_lo = 1;
                nxt_state = IDLE;
            end

            RECV: begin
                // stay until you can transmit the data back
                nxt_state = RECV;
                receiving = 1;
                if (tbr) begin
                    held_data = databus;
                    start_transmitting = 1;
                    nxt_state = TRANS;
                end
            end

            TRANS: begin
                // stay until done transmitting
                nxt_state = TRANS;
                transmitting = 1;
                if (tbr) begin
                    nxt_state = IDLE;
                end
            end

            default: begin
                // nothing, so return to IDLE
            end
        endcase
    end

endmodule
