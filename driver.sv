// Driver
//
// Takes transactions from the generator and drives them onto the
// FIFO pins, one transaction per clock cycle.

class driver;

  virtual fifo_if        vif;
  mailbox #(transaction) gen2drv;
  int count = 0;   // how many transactions have been driven

  function new(virtual fifo_if vif, mailbox #(transaction) gen2drv);
    this.vif     = vif;
    this.gen2drv = gen2drv;
  endfunction

  task run();
    transaction tr;
    forever begin
      gen2drv.get(tr);
      @(vif.drv_cb);
      vif.drv_cb.wr_en <= tr.wr_en;
      vif.drv_cb.rd_en <= tr.rd_en;
      vif.drv_cb.din   <= tr.din;
      count++;
    end
  endtask

  // Stop driving: put the inputs back to idle on the next clock.
  task idle();
    @(vif.drv_cb);
    vif.drv_cb.wr_en <= 0;
    vif.drv_cb.rd_en <= 0;
  endtask

endclass
