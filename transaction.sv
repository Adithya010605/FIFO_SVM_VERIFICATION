// Transaction
//
// One transaction = what happens on the FIFO in one clock cycle.
//
// "rand" fields are filled in by randomize() in the generator.
// The other fields are filled in by the monitor from what it sees.

class transaction;

  // Stimulus (randomized)
  rand bit       wr_en;
  rand bit       rd_en;
  rand bit [7:0] din;

  // Observed by the monitor
  bit [7:0] dout;
  bit       full;
  bit       empty;

  // Knobs: chance (0-100) that wr_en / rd_en is 1.
  // The generator changes these to steer the FIFO towards full or empty.
  int wr_weight = 50;
  int rd_weight = 50;

  // ------------------------------------------------------------------
  // Constraints
  // ------------------------------------------------------------------

  // Use the knobs to bias reads and writes.
  constraint c_op_weights {
    wr_en dist {1 := wr_weight, 0 := 100 - wr_weight};
    rd_en dist {1 := rd_weight, 0 := 100 - rd_weight};
  }

  // Don't waste cycles doing nothing.
  constraint c_not_idle {
    wr_en || rd_en;
  }

  // Hit the corner values 0x00 and 0xFF more often than pure random would.
  constraint c_data_corners {
    din dist {8'h00 :/ 10, 8'hFF :/ 10, [8'h01:8'hFE] :/ 80};
  }

  function string to_string();
    return $sformatf("wr=%0b rd=%0b din=%02h dout=%02h full=%0b empty=%0b",
                     wr_en, rd_en, din, dout, full, empty);
  endfunction

endclass
