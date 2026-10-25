# Test configuration for uSEQ signal engine

# Define precompiled header path (relative to test directory)
test_pch_file = '../uSEQ/src/pch.h'

# Test compiler arguments (similar to standalone)
test_args = [
  '-DUSE_OWN_ARDUINO_STR',
  '-DUSE_STD_IO',
  '-DNO_ETL',
  '-D__not_in_flash(section)=',
  '-D__not_in_flash_func(x)=',
  '-DENABLE_SIGNAL_ENGINE',
  '-std=c++17'
]

# Include directories
test_inc = include_directories('../uSEQ', '../uSEQ/src')

# Math library dependency
math_dep = declare_dependency(link_args : ['-lm'])

# ===== Signal Engine Tests =====

signal_engine_test_exe = executable(
  'test_signal_engine',
  sources : ['signal_engine/test_signal_engine.cpp'],
  include_directories : test_inc,
  cpp_args : test_args,
  cpp_pch : test_pch_file,
  dependencies : [signal_engine_dep, math_dep]
)

test('signal_engine_test', signal_engine_test_exe)

signal_engine_probe_exe = executable(
  'signal_engine_probe',
  sources : ['signal_engine/signal_engine_probe.cpp'],
  include_directories : test_inc,
  cpp_args : test_args,
  cpp_pch : test_pch_file,
  dependencies : [signal_engine_dep, math_dep]
)

test('signal_engine_probe_smoke', signal_engine_probe_exe)

signal_engine_golden_test_exe = executable(
  'test_signal_engine_golden',
  sources : ['signal_engine/test_signal_engine_golden.cpp'],
  include_directories : test_inc,
  cpp_args : test_args,
  cpp_pch : test_pch_file,
  dependencies : [signal_engine_dep, math_dep]
)

test('signal_engine_golden_test', signal_engine_golden_test_exe)

# ===== Signal Engine Phase 4 Tests =====

signal_engine_phase4_test_exe = executable(
  'test_signal_engine_phase4',
  sources : ['signal_engine/test_signal_engine_phase4.cpp'],
  include_directories : test_inc,
  cpp_args : test_args,
  cpp_pch : test_pch_file,
  dependencies : [signal_engine_dep, math_dep]
)

test('signal_engine_phase4_test', signal_engine_phase4_test_exe)

# ===== Devtools Debug Protocol Contract Tests =====
# Encodes the contract for the devtools debug wire protocol.
# Tests exercise dt::handle_debug_message() actions: capabilities,
# configure, query, status.

devtools_contract_test_exe = executable(
  'test_devtools_contract',
  sources : ['devtools/test_devtools_contract.cpp'],
  include_directories : test_inc,
  cpp_args : test_args + ['-DUSEQ_DEVTOOLS=1'],
  cpp_pch : test_pch_file,
  dependencies : [signal_engine_dep, devtools_dep, math_dep]
)

test('devtools_contract_test', devtools_contract_test_exe, timeout: 30)

# ===== Live-Edit Slot Tests =====

live_edit_test_exe = executable(
  'test_live_edit',
  sources : ['signal_engine/test_live_edit.cpp'],
  include_directories : test_inc,
  cpp_args : test_args,
  cpp_pch : test_pch_file,
  dependencies : [signal_engine_dep, math_dep]
)

test('live_edit_test', live_edit_test_exe)

# ===== Signal Engine Robustness Tests =====

signal_engine_robustness_test_exe = executable(
  'test_signal_engine_robustness',
  sources : ['signal_engine/test_signal_engine_robustness.cpp'],
  include_directories : test_inc,
  cpp_args : test_args,
  cpp_pch : test_pch_file,
  dependencies : [signal_engine_dep, math_dep]
)

test('signal_engine_robustness_test', signal_engine_robustness_test_exe, timeout: 120)

# ===== Output Classification Tests =====

output_classification_test_exe = executable(
  'test_output_classification',
  sources : ['signal_engine/test_output_classification.cpp'],
  include_directories : test_inc,
  cpp_args : test_args,
  cpp_pch : test_pch_file,
  dependencies : [signal_engine_dep, math_dep]
)

test('output_classification_test', output_classification_test_exe)

# ===== UGen Tests =====

ugen_test_exe = executable(
  'test_ugens',
  sources : ['signal_engine/test_ugens.cpp'],
  include_directories : test_inc,
  cpp_args : test_args,
  cpp_pch : test_pch_file,
  dependencies : [signal_engine_dep, math_dep]
)

test('ugen_test', ugen_test_exe)

# ===== State Identity Tests =====

state_identity_test_exe = executable(
  'test_state_identity',
  sources : ['signal_engine/test_state_identity.cpp'],
  include_directories : test_inc,
  cpp_args : test_args,
  cpp_pch : test_pch_file,
  dependencies : [signal_engine_dep, math_dep]
)

test('state_identity_test', state_identity_test_exe)
