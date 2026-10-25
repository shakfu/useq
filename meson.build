project('uSEQ', 'cpp')

# Optional build options are defined in meson_options.txt

# Configure ccache if requested and available
if get_option('use_ccache')
  ccache = find_program('ccache', required: false)
  if ccache.found()
    message('ccache found and enabled for compilation caching')
    message('Note: Ensure ccache is in PATH or set CXX="ccache g++" before meson setup')
  else
    message('ccache not found, continuing without compilation caching')
    message('Install ccache for 80-90% speedup on repeated builds')
  endif
endif

# Configure sanitizer and coverage flags for desktop builds
san_flags = []
cov_flags = []
if get_option('sanitizers')
  san_flags = ['-fsanitize=address,undefined', '-fno-omit-frame-pointer']
endif
if get_option('coverage')
  cov_flags = ['--coverage', '-O0', '-g']
endif

# Add global compiler arguments with sensible warning configuration
common_warning_args = [
  '-Wall',           # Enable most warnings
  '-Wextra',         # Enable extra warnings
  '-Wpedantic',      # Pedantic warnings for ISO C++ compliance
  '-Wno-conversion', # Disable type conversion warnings (embedded code needs flexibility)
  '-Wshadow',        # Warn about variable shadowing
  '-Wunused',        # Warn about unused variables/functions
  '-Wno-unused-parameter', # Disable unused parameter warnings (common in embedded callbacks)
  '-Wuninitialized', # Warn about uninitialized variables
  '-Wdouble-promotion', # Warn about float to double promotions
  '-Wformat=2',      # Strict format string checking
  '-Wnull-dereference', # Warn about null pointer dereferences
]

add_global_arguments(common_warning_args + san_flags + cov_flags, language : 'cpp')

# Define include directories
src_inc = include_directories('uSEQ')

# Define precompiled header for faster compilation
pch_file = 'uSEQ/src/pch.h'

# Define compiler arguments for different targets (early for libraries)
standalone_args = [
  '-DUSE_OWN_ARDUINO_STR',
  '-DUSE_STD_IO',
  '-DNO_ETL',
  '-D__not_in_flash(section)=',
  '-D__not_in_flash_func(x)=',
]

# Add conditional compilation flags based on options
if get_option('minimal_build')
  standalone_args += '-DMINIMAL_BUILD'
  message('Building minimal configuration without optional features')
endif

if get_option('enable_signal_engine')
  standalone_args += '-DENABLE_SIGNAL_ENGINE'
  message('Signal engine enabled')
endif

if get_option('enable_devtools')
  standalone_args += '-DUSEQ_DEVTOOLS=1'
  message('Devtools telemetry enabled')
endif

# === STATIC LIBRARIES FOR PROPER DEPENDENCY TRACKING ===

# Get unity build option and configure override options
unity_build_enabled = get_option('unity_build')
unity_override_options = unity_build_enabled ? ['unity=on'] : ['unity=off']

# Utils library - lowest level, no dependencies
utils_lib = static_library('useq_utils',
  'uSEQ/src/utils/string.cpp',
  'uSEQ/src/utils/common.cpp',
  'uSEQ/src/utils/itoa.cpp',
  'uSEQ/src/utils/log.cpp',
  'uSEQ/src/utils.cpp',
  include_directories : src_inc,
  cpp_args : standalone_args,
  cpp_pch : pch_file,
  override_options : unity_override_options
)

# Create a dependency object for utils
utils_dep = declare_dependency(
  link_with : utils_lib,
  include_directories : src_inc
)

# Devtools library - compile-time-gated telemetry instrumentation
devtools_inc = include_directories('uSEQ/src/devtools')
devtools_lib = static_library('useq_devtools',
  'uSEQ/src/devtools/devtools.cpp',
  include_directories : [src_inc, devtools_inc],
  cpp_args : standalone_args,
  cpp_pch : pch_file,
  dependencies : utils_dep,
  override_options : unity_override_options
)

devtools_dep = declare_dependency(
  link_with : devtools_lib,
  include_directories : [src_inc, devtools_inc],
  dependencies : utils_dep
)

# Signal engine library - depends on utils (symbol_intern.h is header-only)
signal_engine_lib = static_library('useq_signal_engine',
  'uSEQ/src/signal_engine/diagnostics.cpp',
  'uSEQ/src/signal_engine/token.cpp',
  'uSEQ/src/signal_engine/cell_store.cpp',
  'uSEQ/src/signal_engine/node_pool.cpp',
  'uSEQ/src/signal_engine/executor.cpp',
  'uSEQ/src/signal_engine/graph_builder.cpp',
  'uSEQ/src/signal_engine/cold_eval.cpp',
  'uSEQ/src/signal_engine/state_registry.cpp',
  include_directories : src_inc,
  cpp_args : standalone_args,
  cpp_pch : pch_file,
  dependencies : [utils_dep, devtools_dep],
  override_options : unity_override_options
)

signal_engine_dep = declare_dependency(
  link_with : signal_engine_lib,
  include_directories : src_inc,
  dependencies : [utils_dep, devtools_dep]
)

# Add test subdirectory
subdir('test')
