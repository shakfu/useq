# uSEQ Scripts

The build is the root `Makefile` and `CMakeLists.txt`. These are code generators and tools:

- `lisplibrary.py`: convert a LISP library to a C++ header.
- `generate_builtins.clj`, `builtins.edn`, `builtin_template.cpp`: generate the interpreter's builtins.
- `run_bytecode_vm_golden.py`: runs bytecode VM golden fixtures against a probe, for `VM_REWRITE_PROPOSAL.md`; neither the fixtures nor the probe exist yet.
