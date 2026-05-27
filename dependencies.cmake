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

function(my_find_package _NAME)
  set(flags "")
  set(single "VERSION;LICENSE_PATH")
  set(multi "COMPONENTS")
  cmake_parse_arguments(A ${flags} ${single} ${multi} ${ARGN})
  message(STATUS "Adding dependency ${_NAME}")
  
  set(version "")
  if (A_VERSION)
    set(version "${A_VERSION}")
  endif()

  if (A_COMPONENTS)
    find_package(${_NAME} ${version} COMPONENTS ${A_COMPONENTS})
  else() 
    find_package(${_NAME} ${version})
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

my_find_package(Qt6 COMPONENTS Core Qml Quick QuickTest Test)
# QT_CMAKE_EXPORT_NAMESPACE is set inside Qt's cmake scripts, which run inside
# my_find_package (a function scope). Propagate it so that qt6_wrap_cpp and
# AUTOMOC can resolve Qt6::moc in subdirectory scopes.
if(NOT QT_CMAKE_EXPORT_NAMESPACE)
  set(QT_CMAKE_EXPORT_NAMESPACE Qt6)
endif()
my_find_package(Boost)
my_find_package(GTest)
