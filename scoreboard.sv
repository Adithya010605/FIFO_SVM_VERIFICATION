// Scoreboard
//
// Keeps a "golden" model of the FIFO using a SystemVerilog queue,
// and compares the DUT against it every cycle:
//   - the full/empty flags must match the model's size
//   - data read out must match the oldest entry in the model

class scoreboard;

  mailbox #(transaction) mon2scb;
  int depth;

  bit [7:0] model[$];   // reference model: a queue
  int pass_count  = 0;
  int error_count = 0;

  function new(mailbox #(transaction) mon2scb, int depth);
    this.mon2scb = mon2scb;
    this.depth   = depth;
  endfunction

  task run();
    transaction tr;
    bit [7:0]   expected;
    forever begin
      mon2scb.get(tr);

      // 1. Check flags (they describe the state BEFORE this cycle's operation)
      if (tr.empty !== (model.size() == 0))
        report_error($sformatf("empty=%0b but model has %0d entries", tr.empty, model.size()));
      if (tr.full !== (model.size() == depth))
        report_error($sformatf("full=%0b but model has %0d entries", tr.full, model.size()));

      // 2. Read: compare DUT output with the oldest entry in the model
      if (tr.rd_en && !tr.empty) begin
        expected = model.pop_front();
        if (tr.dout === expected)
          pass_count++;
        else
          report_error($sformatf("read %02h, expected %02h", tr.dout, expected));
      end

      // 3. Write: add the new data to the model
      if (tr.wr_en && !tr.full)
        model.push_back(tr.din);
    end
  endtask

  function void report_error(string msg);
    error_count++;
    $error("[SCB] %s", msg);
  endfunction

endclass
