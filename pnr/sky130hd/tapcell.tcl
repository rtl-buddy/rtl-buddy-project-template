# Row cutting around macros for the sky130hd platform.
#
# Referenced by `cfg-pdks.sky130hd.tapcell-tcl` in ../../root_config.yaml. The
# P&R flow sources it after macro placement and the macro keep-outs, before the
# power grid -- the step where ORFS sources its TAPCELL_TCL.
#
# It cuts the standard-cell rows 2 um around every placed macro, as ORFS'
# sky130hd tapcell.tcl does through the default halo of `tapcell`. The macro
# grids in pdn.tcl keep the core grid 2 um off each macro, and pdngen fails
# with PDN-0008 when that halo reaches a row the macro does not sit on.
#
# Unlike ORFS it inserts no tap cells.
cut_rows -halo_width_x 2 -halo_width_y 2
