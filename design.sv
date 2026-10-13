`timescale 1ns/1ps

// Synchronous FIFO (the DUT)
//
// - One clock for both read and write.
// - Write is accepted when wr_en = 1 and the FIFO is not full.
// - Read  is accepted when rd_en = 1 and the FIFO is not empty.
// - dout always shows the oldest entry (first-word fall-through),
//   so the data is valid in the same cycle you assert rd_en.
//
// DEPTH must be a power of 2 so the pointers wrap around naturally.

module sync_fifo #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 8
) (
  input  logic             clk,
  input  logic             rst_n,
  input  logic             wr_en,
  input  logic             rd_en,
  input  logic [WIDTH-1:0] din,
  output logic [WIDTH-1:0] dout,
  output logic             full,
  output logic             empty
);

  localparam int PTR_W = $clog2(DEPTH);

  logic [WIDTH-1:0] mem [DEPTH];
  logic [PTR_W-1:0] wr_ptr, rd_ptr;
  logic [PTR_W:0]   count;          // one extra bit so it can hold DEPTH

  logic do_write, do_read;
  assign do_write = wr_en && !full;
  assign do_read  = rd_en && !empty;

  // Storage (no reset needed for the memory itself)
  always_ff @(posedge clk) begin
    if (do_write)
      mem[wr_ptr] <= din;
  end

  // Pointers and count
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      count  <= '0;
    end else begin
      if (do_write) wr_ptr <= wr_ptr + 1'b1;
      if (do_read)  rd_ptr <= rd_ptr + 1'b1;

      case ({do_write, do_read})
        2'b10:   count <= count + 1'b1;   // write only
        2'b01:   count <= count - 1'b1;   // read only
        default: ;                        // both or neither: no change
      endcase
    end
  end

  assign full  = (count == DEPTH);
  assign empty = (count == 0);
  assign dout  = mem[rd_ptr];

endmodule
