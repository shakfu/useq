# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

uSEQ is a **livecodeable eurorack module** - a hardware music sequencer that can be programmed in real-time using a custom LISP-based language called ModuLisp. It combines embedded firmware (C++), hardware design (KiCad), and software interfaces (Python, Clojure) for live musical performance.

## Agent Workflow

### Issue Tracking

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

Use `bd` for all task tracking. Do not create markdown TODO lists or track work outside beads.

```bash
bd ready --json
bd show <id> --json
bd update <id> --claim --json
bd close <id> --reason "Done" --json
bd dolt push
```

When new follow-up work is discovered, create a linked issue:

```bash
bd create "Issue title" --description="Context" -t bug|feature|task -p 0-4 --deps discovered-from:<parent-id> --json
```

### Non-Interactive Shell Commands

Always use non-interactive flags with shell commands that may prompt.

```bash
cp -f source dest
mv -f source dest
rm -f file
rm -rf directory
cp -rf source dest
scp -o BatchMode=yes ...
ssh -o BatchMode=yes ...
apt-get -y ...
HOMEBREW_NO_AUTO_UPDATE=1 brew ...
```

### WIP Discipline

This repository has active long-running epics. Agents must not be trigger-happy about declaring them complete.

- Treat closed subtasks as completed slices, not proof that the parent epic is done.
- If implementation is partial, first-pass, or knowingly missing semantic coverage, say so explicitly in code review notes, handoffs, and issue wording.
- Do not use language like "replaces the interpreter", "general VM complete", or "closure support done" unless the remaining semantic gaps and regression coverage actually support that claim.
- When you find a known gap that is not being fixed in the current change, file or update a `bd` issue instead of hand-waving it away.

### Session Completion

When ending a work session, finish the operational steps instead of leaving work stranded locally:

1. File issues for remaining work.
2. Run quality gates if code changed.
3. Update issue state.
4. Push all changes:
   `git pull --rebase`
   `bd dolt push`
   `git push`
   `git status`
5. Verify the branch is up to date with origin before handing off.

## Build Commands

CMake, through the root `Makefile`:

```bash
make            # configure and build into build/ (Debug)
make test       # build, then run every CTest suite
make sanitize   # build and test with ASan and UBSan, in build-sanitize/
make coverage   # build and test with coverage, in build-coverage/
cd build && ctest -R test_ugens --output-on-failure   # one suite
```

`JOBS` defaults to 4; never build with every core (it has made the machine unusable). `TYPE` sets the build type, `CMAKE_ARGS` passes options such as `-DUSEQ_DEVTOOLS=OFF`.

## Core Architecture

### Project Structure
```
/src/
├── signal_engine/             # Signal compiler and runtime
│   ├── graph_builder.{h,cpp}  # Compiler: ModuLisp → node graph
│   ├── node_pool.{h,cpp}      # CSE, constant folding, node storage
│   ├── executor.{h,cpp}       # Per-sample hot-path evaluation
│   ├── cold_eval.{h,cpp}      # Cold eval: REPL, cell assign, output def
│   ├── cell_store.{h,cpp}     # Named cells and data tables
│   ├── token.{h,cpp}          # Tokenizer
│   ├── diagnostics.{h,cpp}    # Structured error reporting
│   ├── state_registry.{h,cpp} # State-identity resource registry
│   ├── signal_engine.h        # SignalEngine composition struct
│   ├── types.h                # Shared types (Node, Cell, Output, etc.)
│   └── symbols.def            # X-macro symbol definitions
├── firmware/                  # Hardware abstraction
│   ├── firmware.{h,cpp}       # Composition root, init(), tick() loop
│   ├── hardware_io.{h,cpp}    # All pin I/O, variant pin maps, LEDs
│   ├── serial_protocol.{h,cpp}# JSON wire protocol dispatch
│   ├── flash_storage.{h,cpp}  # LittleFS persistence
│   ├── i2c_network.{h,cpp}    # Multi-module I2C communication
│   ├── dsp_engine.{h,cpp}     # Core 1 stub (P3)
│   └── utils/                 # piopwm.h, ResponsiveAnalogRead
├── utils/                     # String, JSON builder, log, serial_message
├── modulisp/lisp/symbol_intern.h  # Symbol interning (shared)
└── ports/                     # IStorage.h, MockStorage.h (testability)

/wasm/wasm_wrapper.cpp         # WASM bindings (15 exports)
/test/                         # signal_engine/ and firmware/ test suites
/docs/specs/                   # Normative specs (MAIN.md is the index)
/scripts/                      # Build, test, flash scripts
```

### Key Components

1. **Signal Engine** (`signal_engine/`)
   - Compiles ModuLisp to a node DAG, evaluates per-sample via flat arrays
   - `graph_builder.cpp` — compiler with form dispatch table, X-macro symbols
   - `executor.cpp` — hot path: linear scan of topological order, zero allocation
   - `cold_eval.cpp` — cold path: parses + compiles on eval, manages cells/outputs
   - `node_pool.h` — hash-consed node pool with CSE + constant folding

2. **Firmware** (`firmware/`)
   - Thin wrapper: reads inputs → runs engine → writes outputs
   - `hardware_io.cpp` — all variant pin maps inline under `#ifdef` guards
   - `serial_protocol.cpp` — JSON wire protocol (hello, ping, eval, stream-config)
   - `flash_storage.cpp` — LittleFS persistence with CRC32 validation

3. **JSON Protocol** (`utils/`)
   - `log.cpp/h`: `Protocol` namespace — JSON mode toggle, request tracking
   - `json_builder.h`: Lightweight fluent JSON builder (no external libs)
   - `serial_message.h`: Wire-level constants (start marker `0x1F`)

## Error Handling and Diagnostics

The signal-engine compiler produces structured diagnostics that flow through to the browser editor as inline annotations. Specs: `docs/specs/diagnostics.md` (wire format), `docs/specs/failure-model.md` (LKG, health states).

### Key files

- `signal_engine/diagnostics.{h,cpp}` — `Diagnostic`, `DiagnosticSeverity`, `DiagnosticCategory`, `severity_to_cstr()`, `category_to_cstr()`, fuzzy matching
- `signal_engine/graph_builder.cpp` — compiler uses `report_error_at_cat()` (fatal) and `report_and_continue()` (non-fatal). Fuzzy matching suggests corrections for typos.
- `signal_engine/cold_eval.cpp` — `SignalEngine` owns diagnostics vector, accessed via `get_diagnostics()`, `clear_diagnostics()`
- `wasm/wasm_wrapper.cpp` — `useq_last_diagnostics()` (JSON array from last eval) and `useq_active_diagnostics()` (per-output health state)
- `firmware/serial_protocol.cpp` — firmware includes diagnostics in serial JSON eval responses

### Diagnostic flow

```
User code → Tokenizer (token.cpp) → GraphBuilder (diagnostics) → SignalEngine
  → WASM useq_last_diagnostics() → Frontend JSON parse → CodeMirror inline annotations
```

### Adding a new error

1. In the compiler (`graph_builder.cpp`), call `report_error_at_cat()` for fatal or `report_and_continue()` for non-fatal:
   ```cpp
   return report_error_at_cat(DiagnosticCategory::Arity,
          span_start, span_len, "fn needs N values", "Try: (fn arg1 arg2)");
   ```
2. Use plain language — no jargon in user-facing messages
3. Always include a `suggestion` with working example code
4. The diagnostic propagates automatically through the WASM ABI to the editor

### Important constraints

- `make` uses `JOBS=4` — never compile with full parallelism (bricks the machine)
- Diagnostics are compile-time only — never allocated on the per-sample hot path

## Development Workflows

### Hardware Configuration
- Pin maps: defined inline in `firmware/hardware_io.cpp` under per-variant `#ifdef` guards
- Variant selection: PlatformIO environments in `platformio.ini` pass `-D MUSICTHING` etc.
- No separate configure.h — feature flags are PIO build flags

### Live Coding Interface
```bash
# Run the Python editor
python interfaces/useqedit/useqedit.py

# Send code to module: Ctrl+L
# Immediate execution: prefix with @
# Queue for next bar: no prefix
```

## Important Configuration

### Hardware Variants

The firmware supports multiple hardware configurations:

- **musicthing** (default) - Music Thing Modular variant
  - All features enabled (DSP, I2C, tempo estimation, RGB LED)
  - Inverted outputs for Music Thing hardware

- **hardware_v0_2** - uSEQ Hardware v0.2
  - DSP, I2C networking, rotary encoder

- **hardware_v1_0** - uSEQ Hardware v1.0
  - DSP, I2C, tempo estimation, no encoder

- **minimal** - Minimal build for testing
  - Core features only, reduced binary size

- **musicthing-debug** - Debug build with symbols
  - Reduced optimization, debug output

- **musicthing-verbose** - Extra verbose serial output

### Compiler Flags
- Desktop: `USE_OWN_ARDUINO_STR`, `USE_STD_IO` (public on `useq_utils`); `USEQ_DEVTOOLS=1` on the libraries by default
- Warnings (`useq_options` in `CMakeLists.txt`): `-Wall`, `-Wextra`, `-Wpedantic`, `-Wshadow`; disabled: `-Wno-conversion`, `-Wno-unused-parameter`

## Real-time Constraints

- **Dual-core Architecture**: Signal engine on core 0, core 1 reserved (P3 DSP stub)
- **Timing System**: Functional rendering with phasors (beat, bar, phrase, section)
- **Update Rate**: Runs as fast as possible, not fixed quantum
- **Hot path (executor.cpp)**: Zero allocation, no virtual dispatch, linear scan
- **I2C Networking**: Multi-module communication for synchronized performance

## Testing Strategy

Test suites in `test/signal_engine/` and `test/devtools/`, one CTest test each:
- **test_signal_engine**: Core compiler + executor (138 test cases)
- **test_signal_engine_golden**: Golden semantic tests (data-driven, 1000+ assertions)
- **test_signal_engine_phase4**: Advanced features (robustness, edge cases)
- **test_signal_engine_robustness**: Fuzz and stress tests
- **test_ugens**: State-bearing unit generators (slew, env-follow, etc.)
- **test_output_classification**: Output type classification
- **test_live_edit**: Live-edit state identity tests
- **test_state_identity**: Identity of anonymous stateful expressions
- **test_devtools_contract**: Devtools debug protocol
- **signal_engine_probe**: Smoke run of the engine

Run tests frequently during development to ensure stability.

## Documentation References

- **Canonical Specs**: `/docs/specs/MAIN.md` - ModuLisp semantics index

## Language Stack

1. **C++17/20** - Core firmware and interpreter
2. **Python** - Live coding editor and utilities
3. **Clojure** - Code generation scripts (if needed)
4. **LISP** - Domain-specific language for sequencing

## Critical Files to Understand

1. `src/signal_engine/signal_engine.h` — composition struct (owns CellStore, NodePool, SourceArena)
2. `src/signal_engine/graph_builder.cpp` — the compiler (ModuLisp → node DAG)
3. `src/signal_engine/executor.cpp` — the hot path (per-sample node evaluation)
4. `src/signal_engine/cold_eval.cpp` — cold path (REPL eval, cell/output management)
5. `src/firmware/firmware.cpp` — tick loop (the main runtime loop)
6. `wasm/wasm_wrapper.cpp` — WASM bindings (15 exports for the web editor)
7. `test/signal_engine/test_signal_engine_golden.cpp` — golden semantic tests
