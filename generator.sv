// Generator
//
// Creates randomized transactions and sends them to the driver
// through a mailbox.
//
// The test runs in phases. Each phase changes the read/write weights
// so the FIFO is pushed into the corner cases we want to cover.

class generator;

  mailbox #(transaction) gen2drv;
  int total = 0;   // how many transactions were sent in total

  function new(mailbox #(transaction) gen2drv);
    this.gen2drv = gen2drv;
  endfunction

  // Send 'count' transactions using the given write/read weights.
  task run_phase(string name, int count, int wr_weight, int rd_weight);
    transaction tr;
    $display("[GEN] phase %-6s : %0d transactions (wr %0d%%, rd %0d%%)",
             name, count, wr_weight, rd_weight);
    repeat (count) begin
      tr = new();
      tr.wr_weight = wr_weight;
      tr.rd_weight = rd_weight;
      if (!tr.randomize())
        $fatal(1, "[GEN] randomize() failed");
      gen2drv.put(tr);
      total++;
    end
  endtask

  task run();
    run_phase("fill",   30, 90, 10);   // mostly writes  -> reach full
    run_phase("both",    5, 100, 100); // read+write while full
    run_phase("drain",  30, 10, 90);   // mostly reads   -> reach empty
    run_phase("both",    5, 100, 100); // read+write while empty
    run_phase("mixed", 200, 50, 50);   // random traffic
  endtask

endclass
