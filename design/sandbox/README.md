# Run sandbox unit tests

To run the `basic` test, execute the following command:

    cd ../../verif/sandbox
    ../../venv/bin/python -m rtl_buddy test basic -c tests.yaml


To run all tests:

    cd ../../verif/sandbox
    ../../venv/bin/python -m rtl_buddy test -c tests.yaml


# Test Definition

The testplan (TP) is described in [../../verif/sandbox/tests.yaml](../../verif/sandbox/tests.yaml). The TP contains a list of tests, each test has an associated testbench and verilog-model. Verilog models are defined in the model definition file `models.yaml` described below.

# Model Definition

The verilog models are described in [models.yaml](models.yaml).
