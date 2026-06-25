include_guard(GLOBAL)
include(dependencies)

my_find_package(Qt6 
    COMPONENTS Core Widgets Gui Test
    LICENSE_PATH licenses/LICENSES/LGPL-3.0-only.txt
)

# QT_CMAKE_EXPORT_NAMESPACE is necessary for using moc, rcc and uic to be 
# used with qt6_wrap_cpp etc.
if(NOT QT_CMAKE_EXPORT_NAMESPACE)
  set(QT_CMAKE_EXPORT_NAMESPACE Qt6)
endif()

my_find_package(Boost
    LICENSE_PATH licenses/LICENSE_1_0.txt
)

my_find_package(GTest)
