# `ip_async_fifo` — Gray-code Dual-Clock Async FIFO

A slim demonstrator FIFO that crosses two independent clock domains
using gray-coded read/write pointers and 2-FF synchronizers. Used in
[`demo_tiny_alu_subsys`](../demo_tiny_alu_subsys/) as the streaming input path that lets the
APB host push (op, a, b) records on its own clock and the compute
domain drain them at its own rate.

## Parameters

| Parameter | Default | Notes                                   |
|-----------|---------|-----------------------------------------|
| `DEPTH`   | 8       | must be a power of 2                    |
| `DATA_W`  | 8       | payload width                           |

## Ports

| Group   | Dir | Signal     | Notes                                            |
|---------|-----|------------|--------------------------------------------------|
| Write   | in  | `wclk`     | write-side clock                                 |
| Write   | in  | `wrst_n`   | write-side async reset (active low)              |
| Write   | in  | `wr_en`    | push when high and `!wr_full`                    |
| Write   | in  | `wr_data`  | payload                                          |
| Write   | out | `wr_full`  | full flag, valid in wclk                         |
| Read    | in  | `rclk`     | read-side clock                                  |
| Read    | in  | `rrst_n`   | read-side async reset                            |
| Read    | in  | `rd_en`    | pop when high and `!rd_empty`                    |
| Read    | out | `rd_data`  | head-of-FIFO data (combinational from `mem[]`)   |
| Read    | out | `rd_empty` | empty flag, valid in rclk                        |

## Behaviour summary

- Write side advances its gray-coded `wptr_gray` on accepted pushes.
- Read side advances `rptr_gray` on accepted pops.
- Each pointer is synchronized into the opposite domain via 2 flops.
- `wr_full` true when next-write-gray equals (read-gray with top two
  bits flipped) — standard async-FIFO full criterion.
- `rd_empty` true when `rptr_gray == wptr_gray_in_r`.

## Coverage

See [`specs.yaml`](specs.yaml). Exercised standalone in
[`verif/ip_async_fifo/`](../../verif/ip_async_fifo/) and via the
streaming-input path in `demo_tiny_alu_subsys`.
