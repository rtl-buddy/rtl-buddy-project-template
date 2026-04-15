# cocotb envvars
export PYGPI_PYTHON_BIN=$(which python)

# gen verilator makefiles
export VERILATOR_DUMP_ARGS="--trace --trace-fst --trace-structs +define+DUMP"
verilator --exe --timescale 1ns/10ps +1800-2023ext+sv -sv -cc --x-initial unique --assert --assert-case -Wall -Wwarn-lint -Wno-DECLFILENAME -Wno-PINCONNECTEMPTY -Wno-UNUSEDPARAM -Wno-UNUSEDSIGNAL -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -o simv --trace --trace-fst --trace-structs +define+DUMP --prefix Vtop --vpi --public-flat-rw -LDFLAGS "-Wl,-rpath,$(cocotb-config --lib-dir) -L$(cocotb-config --lib-dir) -lcocotbvpi_verilator" $(cocotb-config --share)/lib/verilator/verilator.cpp --timing --top-module tb_top -f run.f
# make verilator binary simv
make -C obj_dir -f Vtop.mk

# set the toplevel design unit
export COCOTB_TOPLEVEL=tb_top

# v1.9.2 compatibility
# export TOPLEVEL=${COCOTB_TOPLEVEL} 

# set the COCOTB_TEST_MODULES (python test filename)
export COCOTB_TEST_MODULES=test_tb_top

# v1.9.2 compatibility
# export MODULE=${COCOTB_TEST_MODULES}

# run simv
obj_dir/simv
