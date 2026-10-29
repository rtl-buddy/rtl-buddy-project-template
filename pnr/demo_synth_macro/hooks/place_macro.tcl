# `macro-placement` hook of demo_synth_macro_sky130_hooks_pnr: puts each hard
# macro at a fixed location instead of letting RTL-MP choose one.
#
# rb sources this in place of its own macro placement, only when the netlist
# has a macro, with `$block` (the OpenROAD database block) and `$macros` (every
# hard-macro instance) set. It then puts its standard-cell keep-out
# (`placement.macro-cell-halo`) around each macro and builds the power grid,
# so this file only has to locate the macros.

# Lower-left corner of each macro, in microns. Keep a macro at least as far
# from the core edges and from other macros as the PDK's
# `placement.macro-channel` (80 um on sky130hd), the channel RTL-MP would leave,
# or pdngen may be unable to fit its straps.
set macro_locations {
  i_macro {130.0 130.0}
}

# Corners snap down onto the standard-cell site grid, counted from the first
# row's origin, so a macro's bottom edge sits on a row boundary.
set row [lindex [$block getRows] 0]
lassign [$row getOrigin] row_x row_y
set site_w [[$row getSite] getWidth]
set site_h [[$row getSite] getHeight]

foreach inst $macros {
  set name [$inst getName]
  if {![dict exists $macro_locations $name]} {
    error "no location for macro $name"
  }
  lassign [dict get $macro_locations $name] x_um y_um
  set x [expr {int(round([ord::microns_to_dbu $x_um]))}]
  set y [expr {int(round([ord::microns_to_dbu $y_um]))}]
  set x [expr {$row_x + ($x - $row_x) / $site_w * $site_w}]
  set y [expr {$row_y + ($y - $row_y) / $site_h * $site_h}]
  $inst setOrient R0
  $inst setLocation $x $y
  $inst setPlacementStatus FIRM
  puts "placed $name at ([ord::dbu_to_microns $x], [ord::dbu_to_microns $y]) um"
}
