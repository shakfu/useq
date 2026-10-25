# uSEQ

uSEQ is a livecodeable eurorack module.

There's a paper on it here: 

Kyriakoudis, Dimitris, & Kiefer, Chris. (2023, April 19). uSEQ: A LISPy Modular Sequencer for Eurorack with a Livecodable Microcontroller. 7th International Conference on Live Coding (ICLC2023), Utrecht, The Netherlands. https://doi.org/10.5281/zenodo.7843874

uSEQ modules set up within eurorack performance systems


## Features:

* Open source hardware and software
* Low-cost DIY project
* Live code using a simple LISP language library, from a laptop or mobile device, using serial-over-USB
* Stream waveforms back over USB serial to a computer, and route it to MIDI or OSC, linking the modular with software and external hardware
* Livecoding engine with flexible timing and varied options for creating gate and CV patterns (from basic waveforms to euclidean sequencing) and structuring arrangements


More info from [https://www.emutelabinstruments.co.uk/useq/](https://www.emutelabinstruments.co.uk/useq/)

## Canonical Specs

The language specs live in [docs/specs/MAIN.md](docs/specs/MAIN.md).

## Building

The ModuLisp signal engine and its tests, for the desktop, with CMake (3.16 or later) and a C++17 compiler:

```text
make            # configure and build into build/
make test       # build, then run the test suites
make sanitize   # the same with ASan and UBSan
make help       # targets and variables
```

The engine is the `useq_signal_engine` library. Another CMake project can add this directory with `add_subdirectory` and link it; the tests then build only with `-DUSEQ_TESTS=ON`.

We welcome pull requests.
