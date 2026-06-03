# Building yosys-slang on macOS

`rb synth` and `rb fpv` can use the [yosys-slang](https://github.com/povik/yosys-slang)
plugin as the SystemVerilog elaboration frontend in place of Yosys's
built-in `read_verilog -sv -defer`. Required for:

- **SV-2017 designs that the built-in frontend rejects** — `import pkg::*`,
  packed-struct typedefs, complex generates, parameterised package imports.
  Affects `rb synth` (and `rb cdc` via pyslang — see end of this doc).
- **Concurrent SVA `|->` / `|=>` / sequence operators** — needed for `rb fpv`
  with `frontend: slang` and the auto-derived vacuity covers in
  [rtl_buddy#134](https://github.com/rtl-buddy/rtl_buddy/issues/134).

This is optional. Only build it if you intend to set
`opts.frontend: "slang"` (or `tool_overrides.yosys.frontend: "slang"`)
on a synthesis or FPV verification. Default `frontend: "verilog"` and the
unset cdc default both use the built-in Yosys frontend and don't need
this plugin.

## Which repo / branch to build

| Use case | Repo + branch |
|---|---|
| `rb synth` with `frontend: slang`, `rb cdc` (no FPV) | povik upstream `master` — sufficient for general SV-2017. |
| `rb fpv` with `frontend: slang` (vacuity covers, `\|->`, etc.) | **[rtl-buddy/yosys-slang](https://github.com/rtl-buddy/yosys-slang) branch `rtl-buddy`** until [povik/yosys-slang#317](https://github.com/povik/yosys-slang/pull/317) lands upstream. Three commits ahead of povik master: the SVA-rebase work + a stale-test fix + a `disable iff` regression fix. Passes 46/46 ctest. |

When in doubt, **build the rtl-buddy fork's `rtl-buddy` branch** — it's a
strict superset of povik master for SV-2017 elaboration and additionally
unlocks `rb fpv`'s `|->` lowering. The rtl-buddy fork tracks
[rtl-buddy/yosys-slang#1](https://github.com/rtl-buddy/yosys-slang/issues/1)
as its vendoring status; once povik upstream merges the SVA work, the
fork will fast-forward and this doc switches back to upstream.

## Prerequisites

Build [Yosys (rtl-buddy fork)](../yosys/SETUP_OSX.md) first — yosys-slang
links against the same Yosys it'll be loaded into. The `Yosys`
binary, `yosys-config` script, and Yosys headers all need to be on
`PATH` / discoverable.

Xcode command-line tools and Homebrew packages from the Yosys build
cover most of what's needed. Slang itself (the C++ parser library)
ships as a yosys-slang submodule, so no separate slang install is
required — but you'll need `cmake` and a recent `clang` (15+) for the
slang sub-build:

```bash
brew install cmake llvm
```

## Clone

The slang library is a submodule, so clone with `--recursive`.

For the rtl-buddy fork (recommended — covers both synth and FPV):

```bash
git clone --recursive https://github.com/rtl-buddy/yosys-slang.git
cd yosys-slang
git checkout rtl-buddy
```

Or povik upstream (sufficient for synth-only / CDC use):

```bash
git clone --recursive https://github.com/povik/yosys-slang.git
cd yosys-slang
```

If you already cloned without `--recursive`:

```bash
git submodule update --init --recursive
```

## Build

```bash
make -j$(sysctl -n hw.logicalcpu)
```

The build invokes CMake on the slang submodule first (~3–8 min on an
M-series Mac), then compiles the yosys-slang glue (~30 s). Output
lands at `build/slang.so` — the plugin file rtl_buddy points at via
`opts.plugin-path`.

## Install (where to put `slang.so`)

Two patterns work; pick whichever fits your setup:

### Option A — leave it in the build tree (no install step)

Use the absolute path in `root_config.yaml`:

```yaml
cfg-synth-tools:
  - name: "yosys"
    tool: "yosys"
    opts:
      frontend: "verilog"                                    # default for safety
      plugin-path: "/path/to/yosys-slang/build/slang.so"     # absolute
```

Or relative to the project root (resolved against the directory
containing `root_config.yaml`):

```yaml
      plugin-path: "../yosys-slang/build/slang.so"
```

### Option B — system install via Yosys's plugin dir

```bash
sudo make install
```

This copies `slang.so` into `$(yosys-config --datdir)/plugins/`
(typically `/usr/local/share/yosys/plugins/slang.so`). Then in
`root_config.yaml`:

```yaml
      plugin-path: "/usr/local/share/yosys/plugins/slang.so"
```

The plugin path is still required even with a system install — Yosys
doesn't auto-discover plugins from its plugin dir; rtl_buddy emits an
explicit `plugin -i <path>` line in the Yosys script.

## Verify

Quick smoke that yosys can load the plugin and `read_slang` registers:

```bash
yosys -p "plugin -i /path/to/yosys-slang/build/slang.so; help read_slang"
# Expected: prints the read_slang help text (long, --top, --std options, etc.)
```

End-to-end smoke through `rb synth` against this template's tiny ALU:

```yaml
# In synth/demo_tiny_alu/synth.yaml, add to the demo_tiny_alu_synth_generic block:
    tool_overrides:
      yosys:
        frontend: "slang"
        plugin_path: "/path/to/yosys-slang/build/slang.so"
```

```bash
uv run rb synth demo_tiny_alu_synth_generic -c synth/demo_tiny_alu/synth.yaml
# Expected: PASS, ~274 gates (vs ~287 with the default verilog frontend —
# slight difference is expected from slang's eager vs yosys's lazy
# elaboration on the same RTL).
```

End-to-end smoke through `rb fpv` (requires the rtl-buddy fork's
`rtl-buddy` branch — see "Which repo / branch to build" above):

```bash
cd fpv/demo_abv/demo_abv_features
uv run rb fpv demo_abv_features_vacuity
# Expected: PASS, COI: 100% (13/13), Vacuity: 1/2 vacuous.
# The 1/2-vacuous signal comes from the deliberately-vacuous `1'b0 |-> …`
# property in demo_abv_features_props_slang.sv. If you see
# `unsupported SVA feature`, you're on povik master — check out the
# `rtl-buddy` branch of the rtl-buddy fork and rebuild.
```

## Notes

- Build time: 3–8 min for the slang submodule on an M-series Mac, then
  near-instant for the glue. Subsequent rebuilds (after `git pull`) are
  much faster — slang is incrementally compilable.
- ABI compatibility: yosys-slang's `slang.so` is built against the
  Yosys headers from the build environment. If you upgrade Yosys, you
  may need to `make clean && make` in yosys-slang too. Mismatched ABI
  manifests as a load-time symbol error.
- `make install` requires `sudo` because it writes to
  `/usr/local/share/yosys/plugins/`. Skip it if you prefer the build-tree
  path approach (Option A).
- The cdc side (`rb cdc` with `frontend: "slang"` on a `cdc.yaml`
  analysis) does **not** use this plugin. `rb cdc` invokes
  `rtl-buddy-cdc lint --frontend slang`, which uses pyslang directly
  (installed via the `[slang]` extra: `pip install rtl-buddy-cdc[slang]`
  or set the dependency to `rtl-buddy-cdc[slang]` in `pyproject.toml`).
  No yosys-slang involvement on the cdc path.
