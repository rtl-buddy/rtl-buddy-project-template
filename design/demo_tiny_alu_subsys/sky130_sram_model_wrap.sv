// Simulation-only wrapper around OpenRAM's behavioural model of
// sky130_sram_1kbyte_1rw1r_32x256_8.
//
// The model itself is not vendored and not modified. It arrives in
// pdk/sky130_sram/ via synth/demo_tiny_alu_subsys_hier/download_pdk.sh, from
// VLSIDA/sky130_sram_macros, and is BSD-3 licensed with the copyright header
// carried in the file the script downloads. Including it rather than copying it
// keeps that licence, and its provenance, attached to the bytes the simulator
// reads.
//
// What this file adds is exactly one thing: the lint scope the model needs.
// OpenRAM writes its port registers with blocking assignments inside
// `always @(posedge clk)`, which is deliberate for a memory model — the input
// registers have to be visible to the negedge read/write blocks in the same
// timestep — and which Verilator reports as BLKSEQ. The project builds with
// -Wall and promotes warnings to errors, so without a waiver the model cannot
// compile. Scoping the waiver here keeps it off the project's own RTL.
//
// Only simulation reads this file. Synthesis reads
// sky130_sram_1kbyte_1rw1r_32x256_8_bb.sv, a port-only blackbox, and takes the
// macro's real behaviour from its Liberty and LEF.

`timescale 1ns/10ps

/* verilator lint_off BLKSEQ */
/* verilator lint_off DECLFILENAME */
/* verilator lint_off WIDTH */
`include "sky130_sram_1kbyte_1rw1r_32x256_8.v"
/* verilator lint_on WIDTH */
/* verilator lint_on DECLFILENAME */
/* verilator lint_on BLKSEQ */
