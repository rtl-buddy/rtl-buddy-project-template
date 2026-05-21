# Building OpenROAD on macOS

These notes reflect a working build on Apple Silicon (arm64) using
Homebrew clang. OpenROAD does not publish official macOS binaries, so a
source build is required.

## Prerequisites

Xcode command-line tools:

```bash
xcode-select --install
```

Homebrew packages:

```bash
brew install bison boost bzip2 cmake eigen flex fmt groff googletest icu4c \
  libomp llvm or-tools pkg-config python spdlog tcl-tk@8 zlib swig yaml-cpp \
  re2 protobuf abseil highs scip
brew link --force libomp
```

LEMON graph library (not in Homebrew core — use the OpenROAD tap):

```bash
brew install The-OpenROAD-Project/lemon-graph/lemon-graph
```

## Clone

```bash
git clone https://github.com/The-OpenROAD-Project/OpenROAD.git
cd OpenROAD
git submodule update --init --recursive
```

## Configure

Use Homebrew clang (Apple clang lacks the OpenMP support OpenROAD
needs):

```bash
mkdir build && cd build

cmake .. \
  -DCMAKE_BUILD_TYPE=RELEASE \
  -DCMAKE_C_COMPILER=/opt/homebrew/opt/llvm/bin/clang \
  -DCMAKE_CXX_COMPILER=/opt/homebrew/opt/llvm/bin/clang++ \
  -DCMAKE_CXX_FLAGS="-DBOOST_STACKTRACE_GNU_SOURCE_NOT_REQUIRED" \
  -DTCL_LIBRARY=/opt/homebrew/opt/tcl-tk/lib/libtcl8.6.dylib \
  -DTCL_HEADER=/opt/homebrew/opt/tcl-tk/include/tcl.h \
  -DUSE_SYSTEM_ABC=OFF \
  -DUSE_SYSTEM_BOOST=OFF \
  -DUSE_SYSTEM_OPENSTA=OFF
```

If cmake cannot find LEMON, set:

```bash
-DLEMON_DIR=$(brew --prefix lemon-graph)/lib/cmake/LEMON
```

## Build

```bash
make -j$(sysctl -n hw.logicalcpu)
```

The binary lands at `build/bin/openroad`.

## Install

Symlink to a directory on `PATH` rather than running `make install`:

```bash
ln -s $(pwd)/build/bin/openroad /usr/local/bin/openroad
openroad -version
```

## Verify

```bash
openroad -version
# Expected output: 26Q2-... (date-based version string)
```

## Notes

- Build takes ~15–20 min on an M-series Mac with `-j$(sysctl -n hw.logicalcpu)`.
- The binary links against Homebrew-installed shared libraries at fixed
  absolute paths (`/opt/homebrew/...`), so a symlink works correctly —
  no `RPATH` issues.
- OR-Tools, SCIP, and HiGHS are pulled from Homebrew; the bundled ABC
  and OpenSTA are built from source (`USE_SYSTEM_ABC=OFF`,
  `USE_SYSTEM_OPENSTA=OFF`).
- OpenROAD is not currently invoked by the template's `rb synth` flow
  (Yosys handles synthesis end-to-end). These notes are kept here for
  downstream projects that want to run place-and-route on the
  synthesized netlist.
