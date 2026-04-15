# New Block Template

Use these files as a template for creating a new design unit.

## design

[design/template](.)

* [models.yaml](models.yaml) - describes the rtl-model
* [`template_top.sv`](template_top.sv) - `template_top` module

## verif

[verif/template](../../verif/template)

* [tests.yaml](../../verif/template/tests.yaml) - describes the testcases
* [`tb_top.sv`](../../verif/template/tb_top.sv) - top-level testbench
* [`example_preproc.py`](../../verif/template/example_preproc.py) - example preproc hook
* [`example_sweep.py`](../../verif/template/example_sweep.py) - example sweep hook

## Coverage Demo

The starter block is also the minimal coverage example for the repo.

From [`verif/template`](../../verif/template), run:

```bash
uv run rb --builder-mode cov test basic -c tests.yaml --coverage-merge --coverage-html
```

This uses the `cov` builder mode in [`root_config.yaml`](../../root_config.yaml) and writes these merged artifacts in `verif/template/`:

* `coverage_merged.dat`
* `coverage_merged.info`
* `coverage_merge.html/`

`lcov` must be installed separately for the HTML export path. Antmicro `coverview` must be installed separately if you want Coverview package generation.
