include_guard(GLOBAL)

if(${CMAKE_BUILD_TYPE} STREQUAL "Coverage" AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  # set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 --coverage")
  # if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  #   string(APPEND CMAKE_CXX_FLAGS_DEBUG " -fprofile-abs-path")
  # endif()
  # set(CMAKE_EXE_LINKER_FLAGS_DEBUG "--coverage")
  # set(CMAKE_SHARED_LINKER_FLAGS_DEBUG "--coverage")
  # set(CMAKE_MODULE_LINKER_FLAGS_DEBUG "--coverage")

  if (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
   set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -O0 --coverage")
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
  elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    # Adding a build target to execute all tests and generate the coverage report
    add_custom_target(gcov
      COMMAND mkdir -p ${CMAKE_BINARY_DIR}/coverage/input
      COMMAND ${CMAKE_CTEST_COMMAND} -C Debug
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
    add_custom_target(lcov
      COMMAND llvm-profdata merge -sparse *.profraw -o coverage.profdata
      COMMAND genhtml --prefix ${CMAKE_BINARY_DIR}/coverage --ignore-errors source ${CMAKE_BINARY_DIR}/coverage/coverage.info --legend --title "commit SHA1" --output-directory=${CMAKE_BINARY_DIR}/coverage/html/
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
    # Make sure to clean up the coverage folder
    set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES coverage)
    set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -fprofile-instr-generate -fcoverage-mapping")
    set(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -fprofile-instr-generate")
    set(CACHE{COVERAGE_TEST_EXECUTABLES} VALUE "" )
    set(CACHE{COVERAGE_PROFILE_FILES} VALUE "" )
    set(CACHE{COVERAGE_SOURCE_FILES} VALUE "" )
  endif()
endif()

function(finalize_coverage)
 if (CMAKE_BUILD_TYPE STREQUAL "Coverage" AND CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    message(STATUS "profile files: ${COVERAGE_PROFILE_FILES}")
    set(profile_files $CACHE{COVERAGE_PROFILE_FILES})
    set(executables $CACHE{COVERAGE_TEST_EXECUTABLES})

    add_custom_command(TARGET gcov POST_BUILD
      COMMAND llvm-profdata merge -sparse ${profile_files} -o ${CMAKE_BINARY_DIR}/coverage/input/data.profdata
      #COMMAND llvm-cov report ${executables} -instr-profile=${CMAKE_BINARY_DIR}/coverage/input/data.profdata -use-color --ignore-filename-regex="tests/unit-tests/"
      #COMMAND llvm-cov export ${executables} -instr-profile=${CMAKE_BINARY_DIR}/coverage/input/data.profdata --ignore-filename-regex="tests/unit-tests/"
      COMMAND llvm-cov show ${executables} -instr-profile=${CMAKE_BINARY_DIR}/coverage/input/data.profdata $CACHE{COVERAGE_SOURCE_FILES} -use-color --format html -output-dir=${CMAKE_BINARY_DIR}/coverage/html
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/coverage/input
    )
    add_dependencies(lcov gcov)
    unset(COVERAGE_PROFILE_FILES CACHE)
    unset(COVERAGE_TEST_EXECUTABLES CACHE)
 endif()
endfunction()

function(add_coverage _NAME)
  if (CMAKE_BUILD_TYPE STREQUAL "Coverage" AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    message(STATUS "Instrument target ${_NAME}")
    if (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
      #target_compile_options(${_NAME} "-g -O0 --coverage")

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
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
      # CMake throws error on the clang coverage compile options, so we provide them gobally
      # target_compile_options(${_NAME} "-fprofile-instr-generate" "-fcoverage-mapping")
      # target_link_options(${_NAME} "-fprofile-instr-generate")
      get_target_property(sc ${_NAME} SOURCES)
      set(cov_sources "")
      foreach(s ${sc})
        cmake_path(IS_RELATIVE s is_relative)
        if(${is_relative})
          if (EXISTS ${_current_directory}/${s})
            set(cov_sources ${cov_sources} ${_current_directory}/${s})
          else()
            message(STATUS "not existing ${_current_directory}/${s}")
          endif()
        else()
          set(cov_sources ${cov_sources} ${s})
        endif()
      endforeach()
      get_target_property(value ${_NAME} TYPE)
      set(cov_sources $CACHE{COVERAGE_SOURCE_FILES} ${cov_sources})
      unset(COVERAGE_SOURCE_FILES CACHE)
      set(CACHE{COVERAGE_SOURCE_FILES} VALUE ${cov_sources})
      if (${value} EQUAL SHARED_LIBRARY)
        set(exes $CACHE{COVERAGE_TEST_EXECUTABLES} --object $<TARGET_FILE:${_NAME}>)
        unset(COVERAGE_TEST_EXECUTABLES CACHE)
        set(CACHE{COVERAGE_TEST_EXECUTABLES} VALUE ${exes})
      endif()  
    endif()
  endif()
endfunction()

function(add_coverage_to_test _NAME)
  set(flags )
  set(single )
  set(multi TESTS)
  cmake_parse_arguments(PARSE_ARGV 1 A "${flags}" "${single}" "${multi}")
  if (CMAKE_BUILD_TYPE STREQUAL "Coverage" AND CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    message(STATUS "Instrument test ${_NAME} for coverage")
    foreach(t ${A_TESTS})
      set_tests_properties(${t} PROPERTIES 
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/coverage/input/${_NAME}/
        ENVIRONMENT LLVM_PROFILE_FILEPATH="${_NAME}-%m-%p.profraw"
      )
    endforeach()

    set(exes $CACHE{COVERAGE_TEST_EXECUTABLES} --object $<TARGET_FILE:${_NAME}>)
    set(profs $CACHE{COVERAGE_PROFILE_FILES} ${CMAKE_BINARY_DIR}/coverage/input/${_NAME}/default.profraw)
    unset(COVERAGE_PROFILE_FILES CACHE)
    unset(COVERAGE_TEST_EXECUTABLES CACHE)

    set(CACHE{COVERAGE_TEST_EXECUTABLES} VALUE ${exes} )
    set(CACHE{COVERAGE_PROFILE_FILES} VALUE ${profs} )

    make_directory(${CMAKE_BINARY_DIR}/coverage/input/${_NAME})
    # message(STATUS "Adding custom target gcov_${_NAME}")
    # add_custom_target(gcov_${_NAME}
    #   WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    # )
    # add_custom_command(TARGET gcov_${_NAME} POST_BUILD
    #   COMMAND echo "LLVM_PROFILE_FILEPATH=${CMAKE_BINARY_DIR}/coverage/input/${_NAME}/default.profraw"
    #   COMMAND llvm-profdata merge -sparse ${CMAKE_BINARY_DIR}/coverage/input/${_NAME}/default.profraw -o ${CMAKE_BINARY_DIR}/coverage/input/${_NAME}.profdata
    #   COMMAND llvm-cov report $<TARGET_FILE:${_NAME}> -instr-profile=${CMAKE_BINARY_DIR}/coverage/input/${_NAME}.profdata -use-color --ignore-filename-regex="tests/unit-tests/"
    #   COMMAND llvm-cov export $<TARGET_FILE:${_NAME}> --ignore-filename-regex="tests/unit-tests/"
    #   WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/coverage/input
    # )
    # add_dependencies(gcov ${_NAME})
    # add_dependencies(gcov_${_NAME} gcov)
    # add_dependencies(lcov gcov_${_NAME})
  endif()
endfunction()
