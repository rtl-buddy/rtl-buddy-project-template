import random
import logging
import copy

# Use logger from rtl_buddy if available
try:
  logger
except NameError:
  # logger not defined: set up standalone logger
  logging.basicConfig(level=logging.DEBUG)
  logger = logging.getLogger(__name__)


# test_cfg object is an instance of TestConfig
# test_cfg.tb is an instance of TestbenchConfig
# You (probably) want to be using deepcopies
# Read more about copy here: https://docs.python.org/3.12/library/copy.html
# Make sure to edit the name too for test results to print nicely
def generate() -> TestConfig:
  gen_test_cfgs = []
  for a in range(2,5):
    for b in range(6,7):
      gen_cfg = copy.deepcopy(test_cfg)
      gen_cfg.name = gen_cfg.name + f'_a{a}_b{b}'
      gen_cfg.set_plusarg('a', a)
      gen_cfg.set_plusarg('b', b)

      gen_test_cfgs.append(gen_cfg)

  return gen_test_cfgs

# Cannot be run by itself, just run the function
# The variable containing the output test_cfgs MUST be called out_test_cfgs !!!!!!
out_test_cfgs = generate()
