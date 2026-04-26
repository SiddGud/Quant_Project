cmake_minimum_required(VERSION 3.16)
project(quant_engine CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

add_compile_options(-O3 -march=native -Wall -Wextra -Wpedantic)

add_executable(quant_engine src/main.cpp)
target_include_directories(quant_engine PRIVATE include)
