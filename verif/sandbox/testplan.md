# sandbox Testplan

See [tb_top.sv](./tb_top.sv) and [../../design/sandbox/test_module.sv](../../design/sandbox/test_module.sv).

---

## SANDBOX-01: Basic plusarg smoke test

Verify that the sandbox testbench accepts plusargs, drives the `test_module_3`
DUT, and completes a passing run with the default end-of-test hook checks.

### Checks

- Set `a=10` through plusargs and confirm the end hook does not inject an error
  from the `a < 8` condition.
- Leave `b` unset so the testbench uses its default initialization and counter
  increment behavior.
- Run with the default `test_cycles` value from `tb_top.sv`.
- Keep `lvm_verbosity=2` for low-noise logging.

---

## SANDBOX-02: Define handling and verbose logging

Verify that the sandbox testbench accepts explicit plusargs and preprocessor
defines while still producing a passing run.

### Checks

- Set `a=8`, `b=10`, and `test_cycles=20`.
- Enable `DEFINE_WO_VALUE` and `DEFINE_WITH_VALUE=1` and confirm the testbench
  compile-time paths are exercised.
- Run with `lvm_verbosity=0` to exercise the more verbose logging setting.
- Confirm the end hook still passes because `a` is not below the error
  threshold.

---

## SANDBOX-03: Regression-disabled define variant

Verify an alternate define configuration is available for ad hoc execution but
disabled from normal regression.

### Checks

- Set `a=8`, `b=10`, and `test_cycles=20`.
- Enable `DEFINE_WITH_VALUE=1` without `DEFINE_WO_VALUE`.
- Keep the test disabled from regression with `reglvl: 10000`.
- Confirm the configuration still passes when run directly.
