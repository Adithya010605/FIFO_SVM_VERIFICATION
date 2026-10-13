// Monitor
//
// Watches the FIFO pins every clock, turns what it sees into a
// transaction, and sends it to the scoreboard.
//
// It also collects functional coverage: "which situations did the
// test actually exercise?"

class monitor;

  virtual fifo_if        vif;
  mailbox #(transaction) mon2scb;
  transaction            tr;   // the transaction being sampled for coverage

  // ------------------------------------------------------------------
  // Functional coverage
  // ------------------------------------------------------------------
  covergroup fifo_cg;

    // Which operation happened this cycle
    cp_op: coverpoint {tr.wr_en, tr.rd_en} {
      bins write_only = {2'b10};
      bins read_only  = {2'b01};
      bins both       = {2'b11};
    }

    cp_full:  coverpoint tr.full;
    cp_empty: coverpoint tr.empty;

    // Data values written (only counted on writes)
    cp_din: coverpoint tr.din iff (tr.wr_en) {
      bins zero = {8'h00};
      bins low  = {[8'h01:8'h7F]};
      bins high = {[8'h80:8'hFE]};
      bins max  = {8'hFF};
    }

    // Every operation must be seen while full and while empty.
    // These are the classic FIFO corner cases.
    op_x_full:  cross cp_op, cp_full;
    op_x_empty: cross cp_op, cp_empty;

  endgroup

  function new(virtual fifo_if vif, mailbox #(transaction) mon2scb);
    this.vif     = vif;
    this.mon2scb = mon2scb;
    fifo_cg      = new();
  endfunction

  task run();
    forever begin
      @(vif.mon_cb);
      if (!vif.mon_cb.rst_n) continue;

      tr       = new();
      tr.wr_en = vif.mon_cb.wr_en;
      tr.rd_en = vif.mon_cb.rd_en;
      tr.din   = vif.mon_cb.din;
      tr.dout  = vif.mon_cb.dout;
      tr.full  = vif.mon_cb.full;
      tr.empty = vif.mon_cb.empty;

      // Only care about cycles where something was requested
      if (tr.wr_en || tr.rd_en) begin
        fifo_cg.sample();
        mon2scb.put(tr);
      end
    end
  endtask

endclass
