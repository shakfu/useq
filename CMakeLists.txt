cmake_minimum_required(VERSION 3.16)
project(uSEQ LANGUAGES CXX)

option(USEQ_DEVTOOLS "Build the libraries with devtools telemetry (USEQ_DEVTOOLS=1)" ON)
option(USEQ_SANITIZERS "Build with ASan and UBSan" OFF)
option(USEQ_COVERAGE "Build with coverage instrumentation" OFF)
if (CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
    set(USEQ_TOP_LEVEL ON)
else ()
    set(USEQ_TOP_LEVEL OFF)
endif ()
option(USEQ_TESTS "Build the tests" ${USEQ_TOP_LEVEL})

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_program(CCACHE ccache)
if (CCACHE AND NOT CMAKE_CXX_COMPILER_LAUNCHER)
    set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE})
endif ()

# this project's warnings and instrumentation; private to its own targets
add_library(useq_options INTERFACE)
target_compile_options(useq_options INTERFACE
        -Wall -Wextra -Wpedantic -Wno-conversion -Wshadow -Wunused -Wno-unused-parameter
        -Wuninitialized -Wdouble-promotion -Wformat=2 -Wnull-dereference)
if (USEQ_SANITIZERS)
    target_compile_options(useq_options INTERFACE -fsanitize=address,undefined -fno-omit-frame-pointer)
    target_link_options(useq_options INTERFACE -fsanitize=address,undefined)
endif ()
if (USEQ_COVERAGE)
    target_compile_options(useq_options INTERFACE --coverage -O0 -g)
    target_link_options(useq_options INTERFACE --coverage)
endif ()

# the desktop build: uSEQ's own Arduino String, and stdio for logging
add_library(useq_utils STATIC
        src/utils/string.cpp
        src/utils/common.cpp
        src/utils/itoa.cpp
        src/utils/log.cpp
        src/utils.cpp)
target_include_directories(useq_utils PUBLIC ${PROJECT_SOURCE_DIR}/src)
target_compile_definitions(useq_utils PUBLIC USE_OWN_ARDUINO_STR USE_STD_IO)

add_library(useq_devtools STATIC src/devtools/devtools.cpp)
target_include_directories(useq_devtools PUBLIC ${PROJECT_SOURCE_DIR}/src/devtools)
target_link_libraries(useq_devtools PUBLIC useq_utils)

add_library(useq_signal_engine STATIC
        src/signal_engine/diagnostics.cpp
        src/signal_engine/token.cpp
        src/signal_engine/cell_store.cpp
        src/signal_engine/node_pool.cpp
        src/signal_engine/executor.cpp
        src/signal_engine/graph_builder.cpp
        src/signal_engine/cold_eval.cpp
        src/signal_engine/state_registry.cpp)
target_link_libraries(useq_signal_engine PUBLIC useq_utils useq_devtools)
# devtools reads the engine's state and the engine calls devtools: a cycle CMake repeats on the link line
target_link_libraries(useq_devtools PUBLIC useq_signal_engine)

foreach (lib useq_utils useq_devtools useq_signal_engine)
    target_link_libraries(${lib} PRIVATE $<BUILD_INTERFACE:useq_options>)
    if (USEQ_DEVTOOLS)
        target_compile_definitions(${lib} PRIVATE USEQ_DEVTOOLS=1)
    endif ()
endforeach ()

if (USEQ_TESTS)
    enable_testing()
    add_subdirectory(test)
endif ()
