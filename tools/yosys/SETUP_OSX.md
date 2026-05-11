# Building Yosys (rtl-buddy fork) on macOS

`rtl_buddy synth` uses the [rtl-buddy fork of Yosys](https://github.com/rtl-buddy/yosys),
which tracks upstream with rtl-buddy-specific patches. Build from source
on macOS — there are no published binaries for the fork.

## Prerequisites

Xcode command-line tools:

```bash
xcode-select --install
```

Homebrew packages (matches the fork's `Brewfile`):

```bash
brew install bash bison flex gawk git graphviz googletest libffi llvm lld \
  pkg-config python3 uv xdot
```

## Clone

```bash
git clone --recursive https://github.com/rtl-buddy/yosys.git
cd yosys
```

If you already cloned without `--recursive`:

```bash
git submodule update --init --recursive
```

## Configure & build

The fork ships a `Makefile.conf` template; pick the clang config:

```bash
make config-clang
make -j$(sysctl -n hw.logicalcpu)
```

## Install

`sudo make install` copies the binaries into `/usr/local/bin/`. The fork
ships an alternative `install-symlinks.sh` that drops symlinks instead,
so subsequent `make` runs in the source tree take effect immediately
without re-installing:

```bash
sudo bash install-symlinks.sh                # default destdir /usr/local/bin
# or
sudo bash install-symlinks.sh --destdir /opt/homebrew/bin
```

Symlinks created: `yosys`, `yosys-abc`, `yosys-config`, `yosys-filterlib`,
`yosys-smtbmc`, `yosys-witness`.

To revert to real copies later, run `sudo make install`.

## Verify

```bash
yosys --version
# Expected: Yosys 0.x ... rtl-buddy/yosys
```

`rtl_buddy synth -c synth/demo_sandbox/synth.yaml` should now elaborate and
synthesize the sandbox ALU (~287 gates tech-independent).

## Notes

- macOS requires `bison`/`flex` from Homebrew (the system versions are
  too old). Make sure `/opt/homebrew/opt/bison/bin` and
  `/opt/homebrew/opt/flex/bin` come before `/usr/bin` on `PATH`, or set
  the relevant env vars.
- Build takes ~5–10 min on an M-series Mac with `-j$(sysctl -n hw.logicalcpu)`.
- The fork tracks upstream — pull periodically and rebuild to pick up
  fixes used by `rtl_buddy`'s synth flow.
