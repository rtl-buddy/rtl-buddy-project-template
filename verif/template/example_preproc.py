import random
import logging

# Use logger from rtl_buddy if available
try:
  logger
except NameError:
  # logger not defined: set up standalone logger
  logging.basicConfig(level=logging.DEBUG)
  logger = logging.getLogger(__name__)


def example_gen(out_path, rand, num_lines):
  logger.info(f'example_preproc.py: out_path = {out_path}, rand = {rand}, num_lines = {num_lines}')
  with open(out_path, 'w') as f:
    if rand:
      for _ in range(num_lines):
        f.write(str(random.randint(1, 100)) + '\n')
    else:
      for i in range(1, num_lines + 1):
        f.write(str(i) + '\n')

def example_modify_test(num_lines):
  old_a = test_cfg.get_plusargs()['a']
  new_a = old_a * num_lines
  test_cfg.set_plusarg('a', new_a)
  logger.info(f'example_preproc.py: Changed plusarg "a" to {new_a}')




out_path = "gen_out.txt"
rand = False
num_lines = 5

if __name__ == "__main__":
  # if example_preproc.py is called by itself
  pass
else:
  # if called by rtl_buddy
  # test_cfg(TestConfig) is in the namespace of this script
  # Modifications to test_cfg will be reflected in the compile and sim steps of rtl-buddy!
  # Unpack any necessary variables here
  test_name = test_cfg.name
  num_lines = test_cfg.get_plusargs()['num_lines']
  rand = test_cfg.get_plusargs()['rand']
  print(f'Running example_preproc.py for test: {test_name}')


example_gen(out_path, rand, num_lines)
example_modify_test(num_lines)
