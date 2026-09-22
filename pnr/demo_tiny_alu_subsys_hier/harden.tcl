# Emit a hardened block's abstract views from its routed OpenROAD database.
#
# Driven by harden.sh, which supplies everything through the environment so
# this file carries no paths of its own:
#
#   RB_HARDEN_ODB   routed .odb written by `rb pnr`
#   RB_HARDEN_TOP   block's top module name
#   RB_HARDEN_OUT   directory to write <top>.lef and <top>.lib into
#   RB_HARDEN_LIBS  Liberty files the run read, newline-separated
#   RB_HARDEN_SDC   the run's post-route SDC
#
# This is the hand-wired stand-in for the `harden: true` key in rtl_buddy#95
# step 1. When that lands, `rb pnr` writes these same two files into the same
# `<artefact-dir>/abstract/` directory as part of the run, and this script and
# harden.sh go away.

set odb  $::env(RB_HARDEN_ODB)
set top  $::env(RB_HARDEN_TOP)
set out  $::env(RB_HARDEN_OUT)
set sdc  $::env(RB_HARDEN_SDC)
set libs [split [string trim $::env(RB_HARDEN_LIBS)] "\n"]

file mkdir $out

# The .odb carries the LEF and the routed design, so no technology data has to
# be read back in — the abstract is derived from the result, not re-derived
# from the inputs. Liberty is not in the database, though: it belongs to the
# STA session, not to the layout. harden.sh reads the run's own generated
# pnr.tcl for the exact set of Liberty files that produced this result, so the
# timing model is characterised against the same libraries the block was
# routed against rather than against whatever the caller happens to name.
foreach lib $libs {
  if {[string length $lib] > 0} { read_liberty $lib }
}

read_db $odb

# The post-route SDC, not the input one: it is the constraints as the flow left
# them, with the clock propagated through the tree CTS actually built. A timing
# model extracted under ideal clocks would understate the block's own insertion
# delay, which is precisely the number the parent needs.
read_sdc $sdc

puts ">>> write_abstract_lef $out/$top.lef"
# -bloat_occupied_layers keeps the block's internal routing out of the parent's
# reach: every layer the block used is reported as blocked over the whole
# footprint, rather than only where wires actually are. It is the conservative
# choice, and the right one for a pipeclean — a parent that routes into a gap
# in a block's own metal is a class of failure this example is not trying to
# have.
write_abstract_lef -bloat_occupied_layers $out/$top.lef

puts ">>> write_timing_model $out/$top.lib"
# OpenSTA's extracted timing model: setup/hold checks on the block's input
# registers and clock-to-out arcs on its outputs, characterised from the routed
# netlist. rtl_buddy#95 step 0 asks whether this is good enough to be the
# standard path; see README.md for what this design's model came out as.
write_timing_model $out/$top.lib

exit 0
