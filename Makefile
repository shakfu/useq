# Frontend to the CMake build. See README.md.

BUILD ?= build
TYPE ?= Debug
# a few jobs, not every core: a full parallel build has made the machine unusable
JOBS ?= 4
CMAKE_ARGS ?=

.PHONY: all build test sanitize coverage clean help

all: build

help:
	@echo "make [build]     configure if needed, build the libraries and tests into $(BUILD)"
	@echo "make test        build, then run the tests"
	@echo "make sanitize    build and test with ASan and UBSan, in build-sanitize"
	@echo "make coverage    build and test with coverage instrumentation, in build-coverage"
	@echo "make clean       remove the build directories"
	@echo "variables: BUILD ($(BUILD)), TYPE ($(TYPE)), JOBS ($(JOBS)), CMAKE_ARGS"

$(BUILD)/CMakeCache.txt:
	cmake -S . -B $(BUILD) -DCMAKE_BUILD_TYPE=$(TYPE) $(CMAKE_ARGS)

build: $(BUILD)/CMakeCache.txt
	cmake --build $(BUILD) -j$(JOBS)

test: build
	cd $(BUILD) && ctest --output-on-failure -j$(JOBS)

sanitize:
	$(MAKE) test BUILD=build-sanitize CMAKE_ARGS=-DUSEQ_SANITIZERS=ON

coverage:
	$(MAKE) test BUILD=build-coverage CMAKE_ARGS=-DUSEQ_COVERAGE=ON

clean:
	rm -rf build build-sanitize build-coverage
