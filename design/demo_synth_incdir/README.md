# demo_synth_incdir — RTL

Regression block for [rtl_buddy#69][1] — `+incdir+` entries in a
filelist must be honoured by `\`include` resolution and must not appear
as `read_verilog` sources in the generated Yosys script. The original
bug emitted a spurious `read_verilog -sv -defer <directory>` line into
`artefacts/<name>/synth.ys`, causing Yosys to abort with:

```text
ERROR: File `…/design/demo_synth_incdir' not found or is a directory
```

## Shape

| file                              | role                                                |
| --------------------------------- | --------------------------------------------------- |
| `demo_synth_incdir.sv`            | trivial registered adder, `` `include``s the header |
| `demo_synth_incdir_defs.svh`      | header, picked up via `+incdir+.`                   |
| `test_modules.f`                  | filelist containing the `+incdir+.` entry           |
| `models.yaml`                     | `-F test_modules.f`                                 |

## Running

```bash
uv run rb synth demo_synth_incdir_synth_generic \
  -c synth/demo_synth_incdir/synth.yaml
```

Listed in `synth_regression.yaml`, so `rb synth-regression` covers it
automatically. A failure here would indicate that `+incdir+` filelist
handling has regressed — re-read `rtl_buddy/src/rtl_buddy/tools/synth_yosys.py`
and confirm `_write_filelist` is **not** passing `strip=True`.

[1]: https://github.com/rtl-buddy/rtl_buddy/issues/69
