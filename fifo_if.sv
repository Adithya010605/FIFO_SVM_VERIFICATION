// FIFO interface
//
// Bundles all FIFO signals in one place so the testbench classes can
// reach them through a single "virtual interface" handle.
//
// Clocking blocks remove race conditions:
//   - drv_cb: the driver drives inputs slightly after the clock edge.
//   - mon_cb: the monitor samples everything just before the clock edge.
//
// The assertions live here because they only need the pins, and they
// are checked on every clock no matter what the testbench is doing.

interface fifo_if (input logic clk);

  logic       rst_n;
  logic       wr_en;
  logic       rd_en;
  logic [7:0] din;
  logic [7:0] dout;
  logic       full;
  logic       empty;

  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output wr_en, rd_en, din;
    input  full, empty;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input rst_n, wr_en, rd_en, din, dout, full, empty;
  endclocking

  // ------------------------------------------------------------------
  // Assertions
  // ------------------------------------------------------------------

  // Right after reset the FIFO must be empty and not full.
  property p_reset_empty;
    @(posedge clk) !rst_n |=> (empty && !full);
  endproperty
  a_reset_empty: assert property (p_reset_empty)
    else $error("ASSERT: FIFO not empty after reset");

  // Everything below is ignored while reset is active.

  // Full and empty can never be true together.
  property p_not_full_and_empty;
    @(posedge clk) disable iff (!rst_n) !(full && empty);
  endproperty
  a_not_full_and_empty: assert property (p_not_full_and_empty)
    else $error("ASSERT: full and empty are both high");

  // Status flags must never be X/Z.
  property p_flags_known;
    @(posedge clk) disable iff (!rst_n) !$isunknown({full, empty});
  endproperty
  a_flags_known: assert property (p_flags_known)
    else $error("ASSERT: full/empty is X or Z");

  // Writing into a full FIFO (without reading) must leave it full.
  property p_write_when_full;
    @(posedge clk) disable iff (!rst_n) (full && wr_en && !rd_en) |=> full;
  endproperty
  a_write_when_full: assert property (p_write_when_full)
    else $error("ASSERT: write on full FIFO changed its state");

  // Reading from an empty FIFO (without writing) must leave it empty.
  property p_read_when_empty;
    @(posedge clk) disable iff (!rst_n) (empty && rd_en && !wr_en) |=> empty;
  endproperty
  a_read_when_empty: assert property (p_read_when_empty)
    else $error("ASSERT: read on empty FIFO changed its state");

  // A successful write (no read) means the FIFO cannot be empty next cycle.
  property p_write_clears_empty;
    @(posedge clk) disable iff (!rst_n) (wr_en && !rd_en && !full) |=> !empty;
  endproperty
  a_write_clears_empty: assert property (p_write_clears_empty)
    else $error("ASSERT: still empty after a write");

  // A successful read (no write) means the FIFO cannot be full next cycle.
  property p_read_clears_full;
    @(posedge clk) disable iff (!rst_n) (rd_en && !wr_en && !empty) |=> !full;
  endproperty
  a_read_clears_full: assert property (p_read_clears_full)
    else $error("ASSERT: still full after a read");

  // ------------------------------------------------------------------
  // Cover properties: prove that interesting situations actually happened
  // ------------------------------------------------------------------
  c_became_full:  cover property (@(posedge clk) disable iff (!rst_n) !full  ##1 full);
  c_became_empty: cover property (@(posedge clk) disable iff (!rst_n) !empty ##1 empty);

endinterface
