include_guard(GLOBAL)

if(${CMAKE_BUILD_TYPE} STREQUAL "Coverage" AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 --coverage")
  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    string(APPEND CMAKE_CXX_FLAGS_DEBUG " -fprofile-abs-path")
  endif()
  set(CMAKE_EXE_LINKER_FLAGS_DEBUG "--coverage")
  set(CMAKE_SHARED_LINKER_FLAGS_DEBUG "--coverage")
  set(CMAKE_MODULE_LINKER_FLAGS_DEBUG "--coverage")

  # Adding a build target to execute all tests and generate the coverage report
  add_custom_target(gcov
    COMMAND mkdir -p ${CMAKE_BINARY_DIR}/coverage/input
    COMMAND ${CMAKE_CTEST_COMMAND} -C Debug
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  )
  add_custom_target(lcov
    COMMAND lcov --no-external --capture --ignore-errors empty --directory ${CMAKE_BINARY_DIR}/ --directory ${CMAKE_SOURCE_DIR}/src/ --output-file ${CMAKE_BINARY_DIR}/coverage/coverage.info
    COMMAND genhtml --prefix ${CMAKE_BINARY_DIR}/coverage --ignore-errors source ${CMAKE_BINARY_DIR}/coverage/coverage.info --legend --title "commit SHA1" --output-directory=${CMAKE_BINARY_DIR}/coverage/html/
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  )
  # Make sure to clean up the coverage folder
  set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES coverage)
endif()

macro(testme )
message("${CMAKE_CURRENT_LIST_DIR}")
endmacro()

function(add_coverage _NAME)
  if (CMAKE_BUILD_TYPE STREQUAL "Coverage" AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    message(STATUS "Adding custom target gcov_${_NAME}")
    add_custom_target(gcov_${_NAME}
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
    get_target_property(_sources ${_NAME} SOURCES)
    set(_gcov_files)
    cmake_path(SET bp ${_current_directory}/..)
    foreach(s ${_sources})
      if (${s} MATCHES ".*\\.cpp")
        cmake_path(IS_RELATIVE s _is_relative)
        if (_is_relative)
          list(APPEND _gcov_files $<TARGET_INTERMEDIATE_DIR:${_NAME}>/${s}.gcno)
        elseif(s MATCHES "${_current_directory}.*")
          string(REPLACE "${_current_directory}/" "" _rel ${s})
          list(APPEND _gcov_files $<TARGET_INTERMEDIATE_DIR:${_NAME}>/${_rel}.gcno)
        else()
          get_property(_is_generated SOURCE ${s} PROPERTY GENERATED)
          if (NOT _is_generated)
              list(APPEND _gcov_files ${s}.gcno)
          endif()
        endif()
      endif()
    endforeach()
    add_custom_command(TARGET gcov_${_NAME} POST_BUILD
      COMMAND gcov --relative-only --source-prefix ${CMAKE_SOURCE_DIR} ${_gcov_files}
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/coverage/input
    )
    add_dependencies(gcov ${_NAME})
    add_dependencies(gcov_${_NAME} gcov)
    add_dependencies(lcov gcov_${_NAME})
  endif()
endfunction()