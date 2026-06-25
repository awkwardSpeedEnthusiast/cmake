include_guard(GLOBAL)

########################################################################################
# Declarative test declaration
# 
# my_add_test
#    Define a test executable using GTest
#    Positional:
#      _NAME: name of the test
#    Flags:
#      AUTORCC: CMake automatically compile Qt resource files
#      AUTOMOC: CMake automatically use Qt meta object compiler
#      AUTOUIC: CMake automatically use ui compiler
#    Multi value arguments:
#      HEADER: test header files
#      SOURCE: test source files
#      RESOURCES: Qt resource files
#      FORMS: Qt UI forms
#      QMLS: Qt QML files
#      DEPENDS: libraries or CMake targets to depend on
#      INCLUDES: include directories
#      DEFINES: compile definitions
#      
# my_add_qml_test
#    Define a test executable using GTest, testing QML files
#    Positional:
#      _NAME: name of the test
#    Flags:
#      AUTORCC: CMake automatically compile Qt resource files
#      AUTOMOC: CMake automatically use Qt meta object compiler
#      AUTOUIC: CMake automatically use ui compiler
#    Multi value arguments:
#      HEADER: test header files
#      SOURCE: test source files
#      RESOURCES: Qt resource files
#      FORMS: Qt UI forms
#      QML_FILES: Qt QML files
#      DEPENDS: libraries or CMake targets to depend on
#      INCLUDES: include directories
#      DEFINES: compile definitions
#
########################################################################################

if (BUILD_TESTING)
include(GoogleTest)
include(coverage)

macro(my_add_test)
set(_current_directory ${CMAKE_CURRENT_SOURCE_DIR})
_my_add_test(${ARGV})
endmacro()

function(_my_add_test _NAME)
  set(flags AUTORCC AUTOMOC AUTOUIC)
  set(single WORKING_DIRECTORY)
  set(multi HEADER SOURCE RESOURCES FORMS DEPENDS INCLUDES DEFINES QMLS)
  cmake_parse_arguments(PARSE_ARGV 1 A "${flags}" "${single}" "${multi}")
  message(STATUS "Adding tests ${_NAME}")
  add_executable(${_NAME} ${A_HEADER} ${A_SOURCE} ${A_RESOURCES} ${A_FORMS} ${A_QMLS})

  set(dependencies PRIVATE GTest::gtest_main GTest::gmock)
  if (A_DEPENDS)
    list(APPEND dependencies ${A_DEPENDS})
  endif()
  target_link_libraries(${_NAME} ${dependencies})

  if (A_INCLUDES)
    target_include_directories(${_NAME} ${A_INCLUDES})
  endif()

  if (A_DEFINES)
    target_compile_definitions(${_NAME} ${A_DEFINES})
  endif()

  if (A_AUTORCC)
    set_target_properties(${_NAME} PROPERTIES AUTORCC ON)
  endif()
  if (A_AUTOMOC)
    set_target_properties(${_NAME} PROPERTIES AUTOMOC ON)
  endif()
  if (A_AUTOUIC)
    set_target_properties(${_NAME} PROPERTIES AUTOUIC ON)
  endif()

  set(working_directory ${CMAKE_BINARY_DIR}/tests/) 
  if (A_WORKING_DIRECTORY)
    set(working_directory ${A_WORKING_DIRECTORY})
  endif()

  set_target_properties(${_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/tests/)

  gtest_add_tests(TARGET ${_NAME}
                  SOURCES ${A_SOURCE}
                  WORKING_DIRECTORY ${working_directory}
                  TEST_LIST   mytests
  )
  #message("discovered tests: ${${_NAME}mytests}")
  #add_coverage(${_NAME})
#  foreach(t ${${_NAME}mytests})
    add_coverage_to_test(${_NAME} TESTS ${mytests})
#  endforeach()
  
endfunction()

function(my_add_qml_test _NAME)
  set(flags AUTOMOC AUTOUIC AUTORCC)
  set(single)
  set(multi SOURCE HEADER RESOURCES QML_FILES DEPENDS INCLUDES DEFINES)
  cmake_parse_arguments(PARSE_ARGV 1 A "${flags}" "${single}" "${multi}")
  
  message(STATUS "Adding QML test ${_NAME}")
  
  # Create the test executable with Qt Quick Test runner
  add_executable(${_NAME} ${A_SOURCE} ${A_HEADER} ${A_RESOURCES} ${A_QML_FILES})
  
  # Copy QML test files to build directory for Qt Quick Test discovery
  foreach(_qml_file ${A_QML_FILES})
    configure_file(
      ${CMAKE_CURRENT_SOURCE_DIR}/${_qml_file}
      ${CMAKE_CURRENT_BINARY_DIR}/${_qml_file}
      COPYONLY
    )
  endforeach()
  
  if (A_AUTOMOC)
    if (A_HEADER)
      qt6_wrap_cpp(_moc_sources ${A_HEADER} TARGET ${_NAME})
      target_sources(${_NAME} PRIVATE ${_moc_sources})
    endif()
  endif()
  if (A_AUTORCC)
    set_target_properties(${_NAME} PROPERTIES AUTORCC ON)
  endif()
  if (A_AUTOUIC)
    set_target_properties(${_NAME} PROPERTIES AUTOUIC ON)
  endif()

  # Set up dependencies - Qt Quick Test requires these modules
  set(dependencies Qt6::Core Qt6::Qml Qt6::Quick Qt6::QuickTest)
  if (A_DEPENDS)
    list(APPEND dependencies ${A_DEPENDS})
  endif()
  target_link_libraries(${_NAME} PRIVATE ${dependencies})
  
  if (A_INCLUDES)
    target_include_directories(${_NAME} ${A_INCLUDES})
  endif()
  
  if (A_DEFINES)
    target_compile_definitions(${_NAME} ${A_DEFINES})
  endif()
  
  # Qt Quick Test requires AUTOMOC
  set_target_properties(${_NAME} PROPERTIES
    AUTOMOC ON
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin/
  )
  
  # Add the test to CTest
  add_test(NAME ${_NAME} COMMAND ${_NAME})

  #add_coverage(${_NAME})

  # Set environment variable to use offscreen platform (no display needed)
  set_tests_properties(${_NAME} PROPERTIES
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen"
  )
endfunction()

endif()