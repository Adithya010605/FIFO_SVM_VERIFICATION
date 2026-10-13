`timescale 1ns/1ps

// Top-level testbench
//
// Generates the clock and reset, connects the DUT to the interface,
// and starts the class-based environment.

`include "fifo_if.sv"
`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "environment.sv"

module testbench;

  localparam int DEPTH = 8;

  // Clock: 10 ns period
  logic clk = 0;
  always #5 clk = ~clk;

  // Interface
  fifo_if vif (clk);

  // DUT
  sync_fifo #(.WIDTH(8), .DEPTH(DEPTH)) dut (
    .clk   (clk),
    .rst_n (vif.rst_n),
    .wr_en (vif.wr_en),
    .rd_en (vif.rd_en),
    .din   (vif.din),
    .dout  (vif.dout),
    .full  (vif.full),
    .empty (vif.empty)
  );

  environment env;

  initial begin
    // Waveform dump (open with EPWave on EDA Playground, or GTKWave)
    $dumpfile("dump.vcd");
    $dumpvars(0, testbench);

    // Reset for a few cycles with all inputs idle
    vif.rst_n = 0;
    vif.wr_en = 0;
    vif.rd_en = 0;
    vif.din   = 0;
    repeat (3) @(posedge clk);
    vif.rst_n = 1;

    // Build and run the environment
    env = new(vif, DEPTH);
    env.run();

    $finish;
  end

endmodule
