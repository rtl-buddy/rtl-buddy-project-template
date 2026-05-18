// Package consumed by demo_slang_pkg_top via `import pkg_demo_slang::*`
// in the module port list. The combination — parameterised module that
// imports a package between `module name` and the parameter `#(...)`
// list — is the canonical SV-2017 shape that Yosys's built-in
// `read_verilog -sv -defer` frontend rejects with `TOK_IMPORT,
// expecting '#' or '(' or ';'`. The yosys-slang plugin's `read_slang`
// elaborates it fine.
//
// See ../README.md and tools/yosys-slang/SETUP_OSX.md for how to wire
// this up.

package pkg_demo_slang;
  parameter int DEFAULT_WIDTH = 8;
  typedef logic [DEFAULT_WIDTH-1:0] data_t;
endpackage
