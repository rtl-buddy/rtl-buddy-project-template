# Run sandbox unit tests

To run the `basic` test, execute the following command:

    cd ../../verif/sandbox
    uv run rb test basic -c tests.yaml


To run all tests:

    cd ../../verif/sandbox
    uv run rb test -c tests.yaml


# Coverage example

The repo includes a minimal Verilator coverage example via the `cov` builder mode in [../../root_config.yaml](../../root_config.yaml). The starter version lives in [../../design/template/](../../design/template/); the sandbox below uses the same flow.

To run the sandbox tests and generate one merged HTML coverage report:

    cd ../../verif/sandbox
    uv run rb --builder-mode cov test -c tests.yaml --coverage-merge --coverage-html

This writes merged artifacts in the current directory:

- `coverage_merged.dat`
- `coverage_merged.info`
- `coverage_merge.html/`

`lcov` should be installed separately before using the HTML export path. Antmicro `coverview` should be installed separately if you want Coverview package generation.


# Test Definition

The test plan is described in [../../verif/sandbox/tests.yaml](../../verif/sandbox/tests.yaml). It contains a list of tests, each with an associated testbench and Verilog model.

# Model Definition

The Verilog models are described in [models.yaml](models.yaml).
