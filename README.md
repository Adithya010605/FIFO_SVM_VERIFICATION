# Synchronous FIFO — Class-Based SystemVerilog Verification

A small, readable class-based testbench for a synchronous FIFO, covering:

- **Interface** with clocking blocks
- **Constrained randomization**
- **Assertions** (SVA)
- **Functional coverage** (covergroups)
- **Scoreboard** with a queue-based reference model

## Architecture

```
            gen2drv                                       mon2scb
generator ----------> driver ---> [ sync_fifo ] ---> monitor ----------> scoreboard
 (random      mailbox     (drives    (DUT)      (samples pins,  mailbox   (queue model,
  stimulus)                pins)                 coverage)                 checks data)

                       fifo_if (interface) holds the pins + assertions
```

## Files — read them in this order

| # | File             | What it teaches                                              |
|---|------------------|--------------------------------------------------------------|
| 1 | `design.sv`      | The DUT: an 8-deep, 8-bit synchronous FIFO                   |
| 2 | `fifo_if.sv`     | Interfaces, clocking blocks, **assertions**, cover properties |
| 3 | `transaction.sv` | `rand` fields and **constraints** (`dist`, weighted knobs)   |
| 4 | `generator.sv`   | `randomize()`, mailboxes, steering stimulus in phases        |
| 5 | `driver.sv`      | Virtual interface, driving through a clocking block          |
| 6 | `monitor.sv`     | Sampling pins, **covergroups**, coverpoints, crosses         |
| 7 | `scoreboard.sv`  | Reference model with a queue, checking DUT output            |
| 8 | `environment.sv` | Building and connecting everything, `fork`/`join_none`       |
| 9 | `testbench.sv`   | Top module: clock, reset, DUT instance, start the test       |

## How to run (EDA Playground, no terminal needed)

1. Go to <https://edaplayground.com> and log in (free account).
2. **Left pane (Testbench):** paste `testbench.sv`. Click the **+** tab
   button to add each of the other testbench files with the **same file
   names**: `fifo_if.sv`, `transaction.sv`, `generator.sv`, `driver.sv`,
   `monitor.sv`, `scoreboard.sv`, `environment.sv`.
3. **Right pane (Design):** paste `design.sv`.
4. Left sidebar:
   - *Testbench + Design:* **SystemVerilog/Verilog**
   - *Tools & Simulators:* **Siemens Questa** or **Aldec Riviera Pro**
   - Tick **Open EPWave after run** if you want waveforms.
5. Click **Run**.

You should see this at the end of the log:

```
==================== TEST REPORT ====================
  Transactions driven : 300
  Reads checked       : ...
  Scoreboard errors   : 0
  Functional coverage : 100.00 %
-----------------------------------------------------
  RESULT: TEST PASSED
=====================================================
```

## What each checker does

**Assertions** (`fifo_if.sv`) check rules about the pins on every clock:
- FIFO is empty right after reset
- `full` and `empty` are never high together
- flags are never X/Z
- writing when full / reading when empty changes nothing
- a write clears `empty`, a read clears `full`

**Scoreboard** (`scoreboard.sv`) keeps its own FIFO in a queue and checks:
- every value read out is the oldest value that was written
- `full`/`empty` match the number of entries in the model

**Coverage** (`monitor.sv`) proves the test actually reached the corners:
every operation (write / read / both) while full and while empty,
plus corner data values `0x00` and `0xFF`.

> Lesson from building this: the first version reached only ~96 % coverage —
> "read while full" was never hit. The fix was to drain the FIFO directly
> after filling it (see `generator.sv`). That's what coverage is for.

## Try breaking it

Change one line in `design.sv`, run, and see which checker catches it.
Then undo the change.

| Bug to inject                                                 | Who catches it                    |
|---------------------------------------------------------------|-----------------------------------|
| `assign do_write = wr_en;` (forget the `!full`)               | Assertion `a_write_when_full`     |
| `assign full = (count == DEPTH-1);`                           | Scoreboard (flag mismatch)        |
| Delete the line `if (do_read) rd_ptr <= rd_ptr + 1'b1;`       | Scoreboard (wrong read data)      |

## Ideas to extend

- Add a second test with different phase weights (e.g. a `test` class).
- Add `almost_full` / `almost_empty` outputs plus assertions and coverage for them.
- Make the FIFO depth a parameter that flows into the interface and transaction.
