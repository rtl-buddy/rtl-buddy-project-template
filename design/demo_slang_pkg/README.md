# demo_slang_pkg — yosys-slang frontend demonstrator

Smallest possible SV-2017 design that exercises the [yosys-slang](https://github.com/povik/yosys-slang) elaboration frontend on the synth side. Paired with `synth/demo_slang_pkg/synth.yaml`.

## What this design does

A parameterised flop bank — `WIDTH`-wide register, async-reset, no internal logic. Functionally trivial. The interesting part is the *header*:

```systemverilog
module demo_slang_pkg_top
  import pkg_demo_slang::*;          // <-- the slang-required bit
#(
  parameter int WIDTH = DEFAULT_WIDTH
) (
  ...
);
```

`import pkg::*` placed between `module name` and the parameter `#(...)` list is the canonical SV-2017 construct that Yosys's built-in `read_verilog -sv -defer` frontend rejects with:

```
ERROR: syntax error, unexpected TOK_IMPORT, expecting '#' or '(' or ';'
```

(Original repro is in [rtl_buddy#88](https://github.com/rtl-buddy/rtl_buddy/issues/88).) Moving the import inside the module body doesn't help — Yosys treats `package` declarations as `$abstract` and never resolves the imported names. The yosys-slang plugin's `read_slang` accepts the construct directly.

## How to exercise

1. Build yosys-slang per [`tools/yosys-slang/SETUP_OSX.md`](../../tools/yosys-slang/SETUP_OSX.md). End-state: `slang.so` exists at a known path.
2. Get an `rtl_buddy` install that has the `frontend:` field plumbed through. Three states, depending on where rtl_buddy#90 is in its lifecycle:

   | rtl_buddy state | What goes in the template's `pyproject.toml` `[tool.uv.sources]` |
   |---|---|
   | **Today** — [#90](https://github.com/rtl-buddy/rtl_buddy/pull/90) open, not yet merged | Local editable on the PR branch: `rtl_buddy = { path = "../../../rtl_buddy/.worktrees/pr-88-slang", editable = true }` (or wherever you've checked out `feature/88-slang`) |
   | **After #90 merges into `rtl-buddy/main`** | Local editable on main: `rtl_buddy = { path = "../../../rtl_buddy", editable = true }` (canonical setup — your local main tracks the eventual release) |
   | **After the next `rtl_buddy` release ships** | Bump the pinned `rtl_buddy==<version>` in `[project].dependencies`; remove the `[tool.uv.sources]` override entirely |

   Without one of these, released `rtl_buddy==4.0.0` (the template's current pin) silently drops `frontend: "slang"` from synth.yaml — pyserde lenience — and the synth falls back to `read_verilog`, which fails on this design as documented above. PR #22 itself can't merge until rtl_buddy reaches state 3.

3. Edit `synth/demo_slang_pkg/synth.yaml` to point `tool_overrides.yosys.plugin_path` at your `slang.so`, or set `cfg-synth-tools.opts.plugin-path` in `root_config.yaml` to make it project-wide.
4. Run:

   ```bash
   uv run rb synth demo_slang_pkg_synth_slang -c synth/demo_slang_pkg/synth.yaml
   ```

The block has `reglvl: 1000` so it's excluded from default `rb synth-regression` runs — the template's regression stays runnable on a vanilla install. Bump `--reg-level` to include it once yosys-slang is wired up.

## Why a separate block (not just flipping `frontend` on `demo_tiny_alu`)

The existing `demo_tiny_alu` synth runs cleanly under both frontends (it's plain SV that the Yosys built-in handles fine). Flipping its frontend to slang would just pick a different lowering of the same RTL — useful as a smoke (and exercised that way during PR #90 verification, ~287 → ~274 gate delta) but doesn't *demonstrate* what slang gives you. This block does: an SV construct that genuinely needs the slang frontend.

## Not exercised on the rb cdc side

`rb cdc` uses pyslang (via the `rtl-buddy-cdc[slang]` extra), not yosys-slang. A future cdc-side slang demo would live as a `frontend: "slang"` analysis under `lint/cdc/cdc.yaml`. Out of scope for this block — kept synth-only to mirror what `tools/yosys-slang/SETUP_OSX.md` covers.
