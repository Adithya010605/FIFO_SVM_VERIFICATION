// Environment
//
// Creates all testbench components, connects them with mailboxes,
// runs them in parallel, and prints the final report.
//
//   generator --(gen2drv)--> driver --> [ DUT ] --> monitor --(mon2scb)--> scoreboard

class environment;

  virtual fifo_if vif;

  generator  gen;
  driver     drv;
  monitor    mon;
  scoreboard scb;

  mailbox #(transaction) gen2drv;
  mailbox #(transaction) mon2scb;

  function new(virtual fifo_if vif, int depth);
    this.vif = vif;
    gen2drv  = new();
    mon2scb  = new();
    gen      = new(gen2drv);
    drv      = new(vif, gen2drv);
    mon      = new(vif, mon2scb);
    scb      = new(mon2scb, depth);
  endfunction

  task run();
    // Generator just fills the mailbox, so it finishes right away
    gen.run();

    // These run forever in the background
    fork
      drv.run();
      mon.run();
      scb.run();
    join_none

    // Wait until every transaction has been driven, then let it settle
    wait (drv.count == gen.total);
    drv.idle();
    repeat (5) @(vif.mon_cb);

    report();
  endtask

  function void report();
    $display("");
    $display("==================== TEST REPORT ====================");
    $display("  Transactions driven : %0d", drv.count);
    $display("  Reads checked       : %0d", scb.pass_count + scb.error_count);
    $display("  Scoreboard errors   : %0d", scb.error_count);
    $display("  Functional coverage : %0.2f %%", mon.fifo_cg.get_inst_coverage());
    $display("-----------------------------------------------------");
    if (scb.error_count == 0)
      $display("  RESULT: TEST PASSED");
    else
      $display("  RESULT: TEST FAILED");
    $display("=====================================================");
    $display("");
  endfunction

endclass
