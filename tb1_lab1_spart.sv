`timescale 1ns/1ps
module tb_lab1_spart;

  // Clock and control signals
  reg         CLOCK_50;
  reg         CLOCK2_50;
  reg         CLOCK3_50;
  reg         CLOCK4_50;
  reg  [3:0]  KEY;
  reg  [9:0]  SW;       // Used for baud rate configuration

  // LED outputs (for observing reset and TX/RX indicators)
  wire [9:0]  LEDR;

  // Create a testbench GPIO bus.
  // Your lab1_spart module uses GPIO[3] as TX output and GPIO[5] as RX input.
  // We will drive bit 5 (RX) and monitor bit 3 (TX).
  wire [35:0] tb_GPIO;
  reg         rxd_signal;  // Our simulation “terminal” driving RX
  assign tb_GPIO[5] = rxd_signal; // Drive RX (bit 5)
  
  // The DUT drives TX onto GPIO[3]; we tap it here.
  wire        txd_signal;
  assign txd_signal = tb_GPIO[3];
  
  // Instantiate the DUT (your top-level lab1_spart module)
  lab1_spart dut (
    .CLOCK_50(CLOCK_50),
    .CLOCK2_50(CLOCK2_50),
    .CLOCK3_50(CLOCK3_50),
    .CLOCK4_50(CLOCK4_50),
    .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(),
    .KEY(KEY),
    .LEDR(LEDR),
    .SW(SW),
    .GPIO(tb_GPIO)
  );

  /////////////////////////////////////////////////////////////
  // Clock Generation (50 MHz and four copies of it)
  /////////////////////////////////////////////////////////////
  initial begin
    CLOCK_50 = 0;
    forever #10 CLOCK_50 = ~CLOCK_50;  // 20 ns period
  end
  
  initial begin
    CLOCK2_50 = 0;
    forever #10 CLOCK2_50 = ~CLOCK2_50;
  end
  
  initial begin
    CLOCK3_50 = 0;
    forever #10 CLOCK3_50 = ~CLOCK3_50;
  end
  
  initial begin
    CLOCK4_50 = 0;
    forever #10 CLOCK4_50 = ~CLOCK4_50;
  end

  /////////////////////////////////////////////////////////////
  // Test Sequence
  /////////////////////////////////////////////////////////////
  initial begin
    // Declare variables at the beginning of the block.
    integer i;
    reg [9:0] uart_frame;
    
    // At time 0: assert reset (active low, so KEY[0]=0)
    KEY = 4'b0000;
    // Set baud rate configuration (for example, 2'b00 = 4800 baud)
    SW = 10'b0000000000;
    // Initialize RX (UART idle state is high)
    rxd_signal = 1'b1;
    
    // Wait a few clock cycles for proper initialization
    #100;
    
    // Release reset (set KEY high)
    KEY = 4'b1111;
    #100;
    
    // --------------------------------------------------------
    // Simulate reception of a UART frame on the RX line.
    // Here we “send” the character 'A' (ASCII 0x41).
    // A standard UART frame: 1 start bit (0), 8 data bits (LSB first), 1 stop bit (1)
    // For 'A' (0x41): binary 01000001, LSB first: 1,0,0,0,0,0,1,0.
    // Thus the full frame is: 0,1,0,0,0,0,0,1,0,1.
    // (For simulation we use an arbitrary “bit period” delay, here 200 ns per bit.)
    // --------------------------------------------------------
    
    // Pack the frame so that uart_frame[0] = start, uart_frame[8:1] = data, uart_frame[9] = stop.
    uart_frame = {1'b1, 8'h41, 1'b0};  // stop, data, start
    
    // Wait a short while before transmitting the frame
    #500;
    // Transmit the frame bit by bit on the RX line.
    for (i = 0; i < 10; i = i + 1) begin
      rxd_signal = uart_frame[i];
      #200; // Hold each bit for 200 ns (simulation bit period)
    end
    // Return RX to idle
    rxd_signal = 1;
    
    // Allow time for the DUT to process and (echo) transmit the data
    #5000;
    
    $stop;  // End simulation
  end

  /////////////////////////////////////////////////////////////
  // Optional: Monitor and decode the UART transmission on the TX line.
  /////////////////////////////////////////////////////////////
  initial begin
    // Declare variables at the beginning of the block.
    integer j;
    reg [9:0] rx_frame;
    
    // Wait for a falling edge (start bit) on txd_signal
    @(negedge txd_signal);
    for (j = 0; j < 10; j = j + 1) begin
      #200;                // wait a bit (simulate bit period)
      rx_frame[j] = txd_signal;
    end
    #100;
    $display("Transmitted UART frame (echo): %b", rx_frame);
    $display("Echoed character: %c", rx_frame[8:1]); // bits 1-8 are the data bits
  end

endmodule
