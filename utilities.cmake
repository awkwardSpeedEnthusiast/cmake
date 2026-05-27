include_guard(GLOBAL)

########################################################################################
# Declarative library and executable declaration
# 
# my_add_library
#    Define a library
#    Positional:
#      _NAME: name of the library
#    Flags:
#      INTERFACE: this is an interface library
#      STATIC: this is a static library
#      OBJECT: this is an object library
#      AUTORCC: CMake automatically compile Qt resource files
#      AUTOMOC: CMake automatically use Qt meta object compiler
#      AUTOUIC: CMake automatically use ui compiler
#    Single value arguments:
#      ALIAS: Alias target name
#    Multi value arguments:
#      HEADER: header files
#      SOURCE: source files
#      RESOURCES: Qt resource files
#      FORMS: Qt UI forms
#      QMLS: Qt QML files
#      DEPENDS: libraries or CMake targets to depend on
#      INCLUDES: include directories
#      DEFINES: compile definitioons
#      
# my_add_executable
#    Define an executable
#    Positional:
#      _NAME: name of the executable
#    Flags:
#      AUTORCC: CMake automatically compile Qt resource files
#      AUTOMOC: CMake automatically use Qt meta object compiler
#      AUTOUIC: CMake automatically use ui compiler
#      INSTALL: do install the target
#    Multi value arguments:
#      HEADER: header files
#      SOURCE: source files
#      RESOURCES: Qt resource files
#      FORMS: Qt UI forms
#      QMLS: Qt QML files
#      DEPENDS: libraries or CMake targets to depend on
#      INCLUDES: include directories
#      DEFINES: compile definitioons
#
########################################################################################

set(CMAKE_INCLUDE_CURRENT_DIR ON)  

function(my_add_library _NAME)
  set(flags INTERFACE STATIC OBJECT AUTORCC AUTOMOC AUTOUIC)
  set(single ALIAS )
  set(multi HEADER SOURCE RESOURCES FORMS DEPENDS INCLUDES DEFINES QMLS )
  cmake_parse_arguments(PARSE_ARGV 1 A "${flags}" "${single}" "${multi}")
  
  # Handle Qt resource (.qrc) files
  set(_qrc_resources "")
  if (A_RESOURCES)
    foreach(_qrc_file ${A_RESOURCES})
      qt6_add_resources(_qrc_output ${_qrc_file})
      list(APPEND _qrc_resources ${_qrc_output})
    endforeach()
  endif()
  
  # Handle QML files by creating a Qt resource
  set(_qml_resources "")
  if (A_QMLS)
    qt_add_resources(_qml_resources "${_NAME}_qml"
      PREFIX "/qml/${_NAME}"
      FILES ${A_QMLS}
    )
  endif()
  
  if(${A_INTERFACE})
    message(STATUS "Adding interface library ${_NAME} (alias: ${A_ALIAS})")
    add_library(${_NAME} INTERFACE ${A_HEADER})
  else()
    if(A_STATIC)
      message(STATUS "Adding static library ${_NAME} (alias: ${A_ALIAS})")
      add_library(${_NAME} STATIC ${A_HEADER} ${A_SOURCE} ${A_RESOURCES} ${A_FORMS} ${_qrc_resources} ${_qml_resources})
    else()
      if(A_OBJECT)
        message(STATUS "Adding object library ${_NAME} (alias: ${A_ALIAS})")
        add_library(${_NAME} OBJECT ${A_HEADER} ${A_SOURCE} ${A_RESOURCES} ${A_FORMS} ${_qrc_resources} ${_qml_resources})
      else()
        message(STATUS "Adding shared library ${_NAME} (alias: ${A_ALIAS})")
        add_library(${_NAME} ${A_HEADER} ${A_SOURCE} ${A_RESOURCES} ${A_FORMS} ${_qrc_resources} ${_qml_resources})
      endif()
    endif()
  endif()

  if (A_DEPENDS)
    target_link_libraries(${_NAME} ${A_DEPENDS})
  endif()

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
    if (A_HEADER)
      qt6_wrap_cpp(_moc_sources ${A_HEADER} TARGET ${_NAME})
      target_sources(${_NAME} PRIVATE ${_moc_sources})
    endif()
  endif()
  if (A_AUTOUIC)
    set_target_properties(${_NAME} PROPERTIES AUTOUIC ON)
  endif()

  if (A_ALIAS)
    add_library(${A_ALIAS} ALIAS ${_NAME})
  endif()
endfunction()

function(my_add_executable _NAME)
  set(flags  AUTORCC AUTOMOC AUTOUIC INSTALL)
  set(single )
  set(multi HEADER SOURCE RESOURCES FORMS DEPENDS INCLUDES DEFINES QMLS )
  cmake_parse_arguments(PARSE_ARGV 1 A "${flags}" "${single}" "${multi}")

  message(STATUS "Adding executable ${_NAME}")
  add_executable(${_NAME} ${A_HEADER} ${A_SOURCE} ${A_RESOURCES} ${A_FORMS} ${A_QMLS})

  if (A_DEPENDS)
    target_link_libraries(${_NAME} ${A_DEPENDS})
  endif()

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
  if (A_INSTALL)
    install(TARGET ${NAME})
  endif()

  set_target_properties(${_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin/)

endfunction()

