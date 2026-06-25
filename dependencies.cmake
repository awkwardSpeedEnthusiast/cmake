include_guard(GLOBAL)

#########################################################################
# Wrapper for find_package for conan packages
# 
#  this takes into account installing licenses 
#
# my_find_package
#    positional:
#      _NAME: package name
#    single value arguments:
#      VERSION: package version 
#      LICENSE_PATH: path to the license file to install alongside
#########################################################################

list(APPEND CMAKE_PREFIX_PATH ${CMAKE_BINARY_DIR}/conan/)

function(my_find_package _NAME)
  set(flags "REQUIRED")
  set(single "VERSION;LICENSE_PATH")
  set(multi "COMPONENTS")
  cmake_parse_arguments(A ${flags} ${single} ${multi} ${ARGN})
  message(STATUS "Adding dependency ${_NAME}")
  
  set(version "")
  if (A_VERSION)
    set(version "${A_VERSION}")
  endif()
  
  set(_required "")
  if (A_REQUIRED)
    set(_required "REQUIRED")
  endif()

  if (A_COMPONENTS)
    find_package(${_NAME} ${version} COMPONENTS ${A_COMPONENTS} ${_required})
  else() 
    find_package(${_NAME} ${version} ${_required})
  endif()
  get_property(multiconfig_generator GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
  if (multiconfig_generator)
    set(BUILD_TYPE_UPPER "DEBUG")
  else()
    string(TOUPPER ${CMAKE_BUILD_TYPE} BUILD_TYPE_UPPER)
  endif()

  if (A_LICENSE_PATH)
    install(FILES ${${_NAME}_PACKAGE_FOLDER_${BUILD_TYPE_UPPER}}/${A_LICENSE_PATH} 
            DESTINATION ${CMAKE_INSTALL_PREFIX}/licenses/${_NAME}/License.txt)
  endif()
endfunction()
