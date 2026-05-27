# cmake

Basic CMake and build utilities to be used with C++

## Requirements

* CMake v 3.27 or higher
* Python 3.11 or higher
* A C++ compiler (GCC, Clang, ...)

Optional, though highly recommended:

* clang-format
* clang-tidy

## Structure

### CMake utilities

#### utilitites.cmake

This file contains functions to declaratively define CMake library targets and executable
targets.

##### my_add_library

Declares a CMake library target.

Arguments: _NAME, INTERFACE, STATIC, OBJECT, AUTORCC, AUTOMOC, AUTOUIC, ALIAS, Multi, HEADER, 
SOURCE, RESOURCES, FORMS, QMLS, DEPENDS, INCLUDES, DEFINES

##### my_add_executable

Declare a CMake executable target

Arguments: _NAME, AUTORCC, AUTOMOC, AUTOUIC, INSTALL, HEADER, SOURCE, RESOURCES, FORMS, QMLS, DEPENDS, INCLUDES, DEFINES

#### testSupport.cmake

##### my_add_test

Define a test executable using GTest

Arguments: _NAME, AUTORCC, AUTOMOC, AUTOUIC, HEADER, SOURCE, RESOURCES, FORMS, QMLS, DEPENDS, INCLUDES, DEFINES,

##### my_add_qml_test

Define a test executable using GTest, testing QML files

Arguments: _NAME, AUTORCC, AUTOMOC, AUTOUIC, HEADER, SOURCE, RESOURCES, FORMS, QML_FILES, DEPENDS, INCLUDES, DEFINES,

#### dependences.cmake

##### my_find_package

Wrapper for CMake `find_package` adding an install step for the license:

Arguments: _NAME, VERSION, LICENSE_PATH

### Templates

The templates directory contains a set of useful files to set up your C++ project with CMake and
conan package manager.

#### requirements.txt

If you want to use conan package manager, you'll need python 3.x and some dependencies listed 
in this file, notably `conan`. 

You can use it in a python virtual environment like this:

```bash
# Create and activate python virtual environment
python -m venv .conan-venv
source .conan-venv/bin/activate

# do this once to set up your python packages
python -m pip install -r requirements.txt 
```

#### CMakeLists.txt

Your top level CMake file. Copy this into your top level code directory.
Here go top level definitions for your project.

#### CMakePresets.json

A basic CMake presets file for GCC/Clang builds on Linux.

Also needs to go into the top level code directory.

#### libraries.cmake/conanfile.txt

Here go your dependencies. Which libraries does your build need.

The current versions include Qt6, Boost and GTest (my personal default go-to libraries).
The libraries need to be referenced in both files to work.

And `libraries.cmake` needs to be referenced in your `CMakeLists.txt` to include the libraries
in your build.

There are several versions of conanfile.txt available here for different requirements on the
Qt library. Qt is a huge library with a multitude of modules, which needs ages to build if used 
in full. There are:

* `conanfile_qt_minimal.txt`: about 700 build steps - no GUI elements contained
* `conanfile_qt_widgets.txt`: all GPL modules disabled, Qt Gui and Qt Widgets is enabled, Qt Quick (QML) is not
* `conanfile_qt_qml.txt`: 5200 build steps - QML included; still not everything Qt provides

Copy the respective file to the top level directory and rename it to `conanfile.txt`.

#### .clang-format

This is used with the C++ code beautifier clang-format. If you don't know it yet, DO CHECK IT OUT!

Put this file into your top level code directory and modify it to your liking.

#### .clang-tidy

This is used with the C++ code sanitizer clang-tidy. Check out the clang-tidy extensions for the
common coding IDEs.

#### .gitignore

This repo doesn't contain a `.gitignore` file, because it usually contains paths, which are personal
and reference your build environment and choice of IDE.

Here is a default one you can directly add to your top level repo directory:

```.gitignore
.gitignore
*~
./builds/**
```

## References

* https://cmake.org/cmake/help/latest/index.html
* https://conan.io/
* https://doc.qt.io/qt-6/reference-overview.html
* https://www.boost.org/
* https://google.github.io/googletest/
* https://clang.llvm.org/docs/ClangFormat.html
* https://clang.llvm.org/extra/clang-tidy/
* https://code.visualstudio.com/

