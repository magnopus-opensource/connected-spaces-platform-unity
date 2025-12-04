cmake_minimum_required(VERSION 3.28)
project(MyProj)

set(_DEPS_DIR "${CMAKE_BINARY_DIR}/_deps")

include(FetchContent)
include(cmake/Options.cmake)
include(cmake/GetSwig.cmake)
include(cmake/GetCSP.cmake)

# Global configuration. This should have RelWithDebugInfo in it also, 
# but we don't have CSP libs for it yet. Impressed that CMake forced
# me to declare this. If you add it here, Cmake will tell you at least
# some of the places you need to update as errors.
set(CMAKE_CONFIGURATION_TYPES "Debug;Release" CACHE STRING "" FORCE)

# ---------------- SWIG Codegen ----------------
# Interface (.i) files
set(ROOT_I_DIR "${CMAKE_SOURCE_DIR}/interface" CACHE FILEPATH "Root include directory for all .i files.")
set(_ROOT_I_FILE "${ROOT_I_DIR}/main.i")

set(CSHARP_CSP_NAMESPACE "Csp" CACHE STRING "Namespace that generated Csharp should be placed under")

# Generated code output
set(_GEN_CPP_DIR "${CMAKE_BINARY_DIR}/generated/cpp")
set(_GEN_CS_DIR  "${CMAKE_BINARY_DIR}/generated/cs")

# SWIG module/DLL name. This is the actual library you'd link against the use the API (whist _this_ library links against CSP proper)
set(_WRAPPER_MODULE_NAME "ConnectedSpacesPlatformDotNet")
set(_CPP_WRAPPER_OUT "${_GEN_CPP_DIR}/${_WRAPPER_MODULE_NAME}_wrap.cxx")

# Only set a default if the user has not provided one
if(NOT DEFINED CMAKE_OSX_ARCHITECTURES OR CMAKE_OSX_ARCHITECTURES STREQUAL "")
    message(WARNING
        "CMAKE_OSX_ARCHITECTURES was not set.\n"
        "Defaulting to 'arm64'. You may override this by setting it explicitly."
    )
    set(CMAKE_OSX_ARCHITECTURES "arm64")
endif()


message(STATUS "CMAKE_OSX_ARCHITECTURES ='${CMAKE_OSX_ARCHITECTURES}'")
message(STATUS "_GEN_CPP_DIR='${_GEN_CPP_DIR}'")
message(STATUS "_GEN_CS_DIR='${_GEN_CS_DIR}'")
message(STATUS "_WRAPPER_MODULE_NAME='${_WRAPPER_MODULE_NAME}'")
message(STATUS "_CPP_WRAPPER_OUT='${_CPP_WRAPPER_OUT}'")
message(STATUS "_ROOT_I_FILE='${_ROOT_I_FILE}'")

# When we install swig on unix platforms, it expects to be in /share, but because we're a custom cut we isolate to dependencies
# Tell swig where its internal configs are (adjacent more or less)
set(_INTERNAL_SWG_SEARCH_PATH_GLOBAL "${_SWIG_BINARY_DIR}/share/swig/4.4.0")
set(_INTERNAL_SWG_SEARCH_PATH_CSHARP "${_SWIG_BINARY_DIR}/share/swig/4.4.0/csharp")

# Check if we want to enable unity extensions
set(SWIG_UNITY_FLAG "")
if(ENABLE_UNITY_EXTENSIONS)
    message(STATUS "Enabling SWIG Unity Extensions")
    set(SWIG_UNITY_FLAG "-DSWIG_UNITY_EXTENSIONS=1")
endif()

# Setup SWIG invocation
add_custom_command(
  OUTPUT "${_CPP_WRAPPER_OUT}"
  COMMAND ${CMAKE_COMMAND} -E remove_directory "${_GEN_CPP_DIR}" # Clean up first
  COMMAND ${CMAKE_COMMAND} -E remove_directory "${_GEN_CS_DIR}"
  COMMAND "${CMAKE_COMMAND}" -E make_directory "${_GEN_CPP_DIR}" "${_GEN_CS_DIR}"
  COMMAND "${SWIG_EXE}"
          -I${_CSP_INCLUDE_DIR} # So we can #include CSP's .h files.
          -I${ROOT_I_DIR} # So we can %include our own .i files.
          -I${_INTERNAL_SWG_SEARCH_PATH_CSHARP} # C# search path for SWIG .i lib files. (This should be first as some are named the same)
          -I${_INTERNAL_SWG_SEARCH_PATH_GLOBAL} # Global search path for SWIG .i lib files.
          -c++ -csharp
          -module ${_WRAPPER_MODULE_NAME}
          -dllimport ${_WRAPPER_MODULE_NAME}
          -outdir "${_GEN_CS_DIR}"
          -o "${_CPP_WRAPPER_OUT}"
          -namespace ${CSHARP_CSP_NAMESPACE}
          ${SWIG_UNITY_FLAG} # Optionally enable unity extensions
          -v # Still could be verboser ... There's other options if you need them
          "${_ROOT_I_FILE}"
  DEPENDS "${_ROOT_I_FILE}"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" 
  VERBATIM
)

# ---------------- Build SWIG Output ----------------
if (BUILD_SHARED_LIBS)
  add_library(${_WRAPPER_MODULE_NAME} SHARED "${_CPP_WRAPPER_OUT}")
else()
  add_library(${_WRAPPER_MODULE_NAME} STATIC "${_CPP_WRAPPER_OUT}")
endif()
set_target_properties(${_WRAPPER_MODULE_NAME} PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED YES
  POSITION_INDEPENDENT_CODE ON
  OUTPUT_NAME "${_WRAPPER_MODULE_NAME}" # ConnectedSpacesPlatform.dll/libConnectedSpacesPlatform.so
)

# Add CSP Target to our output library, this produces a final API that can use CSP.
target_link_libraries(${_WRAPPER_MODULE_NAME} PRIVATE _CSP)

# Ensure the wrapper can resolve @rpath by looking in its own folder at runtime.
# This makes the dependent lookup land on the sibling dylib.
set_target_properties(${_WRAPPER_MODULE_NAME} PROPERTIES
    MACOSX_RPATH ON
    INSTALL_RPATH "@loader_path"
    BUILD_RPATH   "@loader_path"
    BUILD_WITH_INSTALL_RPATH TRUE
)

# When building for ios, it will complain, but we don't need to sign (I think...) because we're just a static library
# (Dynamic would need to be signed ... is this why we don't support dynamic on ios?)
set_target_properties(${_WRAPPER_MODULE_NAME} PROPERTIES
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ""
)


include(cmake/PackageInstall.cmake)

# If desired, automatically copy the generated code and libs into the Unity test project.
if(COPY_OUTPUT_TO_UNITY_TEST_PROJECT)
  message(STATUS "\nStarting the copy of latest generated C# code and libraries to the Unity test project...")
  include(cmake/InstallToUnityProject.cmake)
endif()