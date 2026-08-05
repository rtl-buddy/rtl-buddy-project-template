// vim: set ts=2 sw=2 et :
//
// Example support code for this template project.
//
// Lightwieght Verification Methodology (LVM)
// 

`timescale 1ns/10ps

// GlobalLvmTestCore is an unused cross-package singleton helper whose
// `LvmPkg::TestCore::get_singleton()` scope-resolved static call Icarus
// 12 cannot parse; gate it out there.
`ifndef SIM_ICARUS
typedef class GlobalLvmTestCore;
`endif

package LvmPkg;

typedef class TestCore;

// LVM MACROS

`define LVM_INIT_CUSTOM(testname, local_class_name) \
  local_class_name tc; \
  initial begin:tc_init \
    tc = new(testname); \
  end:tc_init \
  final begin:tc_final \
    tc.end_of_test(); \
  end:tc_final \
  `ifdef DUMP \
  initial begin:tc_dump \
  `ifdef VCS \
    $vcdpluson; \
    $vcdplusmemon; \
  `endif \
  `ifdef VERILATOR \
      $dumpfile("dump.fst"); \
      $dumpvars(); \
  `endif \
  `ifdef SIM_ICARUS \
      $dumpfile("dump.vcd"); \
      $dumpvars(); \
  `endif \
  end:tc_dump \
  `endif \

 
// Top-level testbench should call `LVM_INIT(testname)
// at the beginning of the module
`define LVM_INIT(testname) \
  `LVM_INIT_CUSTOM(testname,LvmPkg::TestCore)

// Error Reporting Macros
`define lvm_rpt_inf(fmt_msg) \
  tc.rpt_inf($sformatf fmt_msg)
`define lvm_rpt_wrn(fmt_msg) \
  tc.rpt_wrn($sformatf fmt_msg)
`define lvm_rpt_err(fmt_msg) \
  tc.rpt_err($sformatf fmt_msg)
`define lvm_rpt_fat(fmt_msg) \
  tc.rpt_fat($sformatf fmt_msg)

// Interface class end-of-test hooks. Icarus 12 does not support
// `interface class`, so the hook framework is gated out under
// SIM_ICARUS; TestCore below still reports PASS/FAIL without hooks.
`ifndef SIM_ICARUS
// Interface
interface class TestEndHook;
  pure virtual function void end_of_test(LvmPkg::TestCore c);
endclass

// Empty EndHook
class NullEndHook implements TestEndHook;
  virtual function void end_of_test(LvmPkg::TestCore c);
  endfunction
endclass
`endif

// TestCore
// Core framework for handling test reporting
class TestCore;

  string name;

`ifndef SIM_ICARUS
  local TestEndHook end_hooks[$];
`endif

  const integer RPT_INF = 0;
  const integer RPT_WRN = 1;
  const integer RPT_ERR = 2;
  const integer RPT_FAT = 3;

  integer verbosity = RPT_ERR;

  // Under Verilator 5.050 these report MULTIDRIVEN when a testbench calls
  // rpt_err()/rpt_wrn() from inside an always_ff: it pairs the declaration
  // initialiser with the increment in the report method and treats the class
  // property as a multiply-driven variable. A class property has no drivers to
  // conflict, so the warning cannot apply here — and unlike a module variable
  // there is no way to drop the initialiser, since these are 4-state.
  /* verilator lint_off MULTIDRIVEN */
  integer ninf = 0;
  integer nerr = 0;
  integer nwrn = 0;
  integer nfat = 0;
  /* verilator lint_on MULTIDRIVEN */

  function new(string new_name);
    integer v;
    $display("TestCore(%s) new", new_name);
    this.name = new_name;
    if ($test$plusargs("lvm_verbosity"))
      begin
      // Icarus 12's vvp cannot $value$plusargs directly into a class
      // property; read into a local integer, then assign.
      if ($value$plusargs("lvm_verbosity=%d", v))
        this.verbosity = v;
      $display("set lvm_verbosity=%1d", this.verbosity);
      end
    // Unqualified static-member assignment (Icarus 12 rejects the
    // `TestCore::singleton` scope-resolved l-value form).
    singleton = this;
  endfunction

`ifndef SIM_ICARUS
  function void add_test_end_hook(TestEndHook h);
    this.end_hooks.push_back(h);
  endfunction
`endif

  // TODO randseed

  static local TestCore singleton;

  static function TestCore get_singleton();
    return singleton;
  endfunction
  
  // report information 
  function void rpt_inf(string s);
    ninf++;
    if (this.verbosity <= RPT_INF)
      $display("INF: %t %s", $time, s);
  endfunction

  // report warnings 
  function void rpt_wrn(string s);
    nwrn++;
    if (this.verbosity <= RPT_WRN)
      $display("WRN: %t %s", $time, s);
  endfunction

  // report errors 
  function void rpt_err(string s);
    nerr++;
    if (this.verbosity <= RPT_ERR)
      $display("ERR: %t %s", $time, s);
  endfunction

  // report fatals 
  function void rpt_fat(string s);
    nfat++;
    if (this.verbosity <= RPT_FAT) begin
      $display("FAT: %t %s", $time, s);
    end
    end_of_test();
    $fatal(0);
  endfunction

  // end of test cleanup
  // this is registered with final begin/end in the LVM_INIT macro
  //breaking up the final report printing to make it easier to override in local extensions
  virtual function void report_preface();
    $display("Test Complete");
    $display("-------------------------");
    $display("name : %s", name);
    $display("-------------------------");
`ifndef SIM_ICARUS
    foreach(this.end_hooks[i])
      end_hooks[i].end_of_test(this);
`endif
    $display("-------------------------");
  endfunction

  virtual function void report_values();
    $display("info : %4d", ninf);
    $display("warn : %4d", nwrn);
    $display("error: %4d", nerr);
    $display("fatal: %4d", nfat);
  endfunction

  virtual function void report_result();
    $display("-------------------------");
    $display();
    if (nerr + nfat > 0)
      $display("FAIL (nerr=%3d, nfat=%3d)", nerr, nfat);
    else
      $display("PASS (nwrn=%3d)", nwrn);
  endfunction

  function void end_of_test();
    report_preface();
    report_values();
`ifndef SIM_ICARUS
    foreach(this.end_hooks[i])
      end_hooks[i].end_of_test(this);
`endif
    report_result();
  endfunction

endclass


// LvmComponent class
// For testbench components to extend. Unused by the demo TB; Icarus 12
// rejects calling TestCore's void methods through the handle here, so
// gate it out there.
`ifndef SIM_ICARUS
class LvmComponent;

  TestCore tc; // handle to the TestCore in the testbench top

  function new(TestCore etc);
    this.tc = etc;
  endfunction

  function void rpt_inf(string s);
    tc.rpt_inf(s);
  endfunction

  function void rpt_wrn(string s);
    tc.rpt_inf(s);
  endfunction

  function void rpt_err(string s);
    tc.rpt_inf(s);
  endfunction

  function void rpt_fat(string s);
    tc.rpt_inf(s);
  endfunction

endclass
`endif

endpackage // LvmPkg

`ifndef SIM_ICARUS
class GlobalLvmTestCore;

  static local LvmPkg::TestCore singleton;

  static function LvmPkg::TestCore get_singleton();
    if (singleton==null)
      GlobalLvmTestCore::singleton = LvmPkg::TestCore::get_singleton();
    return GlobalLvmTestCore::singleton;
  endfunction

endclass
`endif
