# Block-level P&R configuration for demo_tiny_alu_subsys_synth_top.

set DESIGN          demo_tiny_alu_subsys_synth_top
set REPO_ROOT       [file normalize [file join [file dirname [info script]] .. ..]]

set NETLIST         $REPO_ROOT/synth/demo_tiny_alu_subsys/artefacts/demo_tiny_alu_subsys_synth_nangate45/synth_netlist.v
set SDC_FILE        $REPO_ROOT/synth/demo_tiny_alu_subsys/constraints.sdc

set PDK_DIR         $REPO_ROOT/pdk/nangate45
set TECH_LEF        $PDK_DIR/lef/NangateOpenCellLibrary.tech.lef
set MACRO_LEF       $PDK_DIR/lef/NangateOpenCellLibrary.macro.mod.lef
set LIBERTY         $PDK_DIR/lib/NangateOpenCellLibrary_typical.lib
set MACRO_GDS       $PDK_DIR/gds/NangateOpenCellLibrary.gds

set SITE            FreePDK45_38x28_10R_NP_162NW_34O

# Floorplan: utilization-driven square die. Bump if congestion shows up.
set CORE_UTIL       0.55
set CORE_ASPECT     1.0
set CORE_MARGIN     2.0

# Std-cell fill candidates (smallest first).
set FILL_CELLS      {FILLCELL_X1 FILLCELL_X2 FILLCELL_X4 FILLCELL_X8 FILLCELL_X16 FILLCELL_X32}

# Tie-cell mapping (Nangate45 names).
set TIEHI_CELL_PORT "LOGIC1_X1/Z"
set TIELO_CELL_PORT "LOGIC0_X1/Z"

# Clock buffer for CTS.
set CTS_BUF         "BUF_X4"

# Power/ground net names (Nangate45 convention).
set VDD_NET         VDD
set VSS_NET         VSS

set OUT_DIR         [file join [file dirname [info script]] artefacts]
file mkdir $OUT_DIR
