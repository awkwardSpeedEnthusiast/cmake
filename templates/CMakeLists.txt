cmake_minimum_required(VERSION 3.27...4.5)

###################################
# conan settings
list(APPEND CMAKE_PROJECT_TOP_LEVEL_INCLUDES ${CMAKE_CURRENT_LIST_DIR}/cmake/cmake-conan/conan_provider.cmake)
set(CONAN_BUILD_PROFILE "default;auto-cmake")
set(CONAN_INSTALL_ARGS "--build=missing")

###################################
# C++ settings
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

###################################
# script directory
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)

###################################
# project definition
project(template 
    VERSION 0.0.1 
    DESCRIPTION "A template description" 
    LANGUAGES CXX
)

## declarative library and executable definitions
include(utilities)

## libraries and dependencies
include(dependencies)

## we have tests
include(CTest)
include(testSupport)

## our productive code
add_subdirectory(src)

## testing stuff
if (BUILD_TESTING)
  enable_testing()
  add_subdirectory(tests)
endif()
