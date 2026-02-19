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

# Generated code output
set(_GEN_CPP_DIR "${CMAKE_BINARY_DIR}/generated/cpp")
set(_GEN_CS_DIR  "${CMAKE_BINARY_DIR}/generated/cs")

# SWIG module/DLL name. This is the actual library you'd link against the use the API (whist _this_ library links against CSP proper)
set(_WRAPPER_MODULE_NAME "ConnectedSpacesPlatformDotNet")
set(_CPP_WRAPPER_OUT "${_GEN_CPP_DIR}/${_WRAPPER_MODULE_NAME}_wrap.cxx")

# Note: for Unity on Mac, CMAKE_OSX_ARCHITECTURES should be set by the user to arm64.
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

# Check if we want to automatically generate ThrowOnFailure code when ResultBase returns a failure status code.
set(THROW_EXCEPTION_ON_RESULTBASE_FAILURE_FLAG "")
if(ENABLE_THROW_EXCEPTION_ON_RESULTBASE_FAILURE)
    message(STATUS "Enabling generation of ThrowOnFailure code for ResultBase failure status codes. 
    This will throw a C# exception when a ResultBase returns a failure status code, instead of just returning the ResultBase with the failure code.")
    set(THROW_EXCEPTION_ON_RESULTBASE_FAILURE_FLAG "-DTHROW_EXCEPTION_ON_RESULTBASE_FAILURE=1")
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
          -dllimport ${SWIG_DLLIMPORT_NAME}
          -outdir "${_GEN_CS_DIR}"
          -o "${_CPP_WRAPPER_OUT}"
          ${SWIG_UNITY_FLAG} # Optionally enable unity extensions
          ${THROW_EXCEPTION_ON_RESULTBASE_FAILURE_FLAG} # Optionally generate ThrowOnFailure code when ResultBase is returned with failure status code.
          -v # Still could be verboser ... There's other options if you need them
          "${_ROOT_I_FILE}"
  DEPENDS "${_ROOT_I_FILE}"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" 
  VERBATIM
)

# ---------------- Build SWIG Output ----------------
if (BUILD_SHARED_LIBS)
  add_library(${_WRAPPER_MODULE_NAME} SHARED "${_CPP_WRAPPER_OUT}")
  # Pretty important, make sure we're importing symbols. Otherwise you'll get duplicate template instances and such. Bad times.
  target_compile_definitions(${_WRAPPER_MODULE_NAME} PRIVATE USING_CSP_DLL)
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

# iOS / visionOS static-force-load
if(CMAKE_SYSTEM_NAME STREQUAL "iOS" OR CMAKE_SYSTEM_NAME STREQUAL "visionOS")
  target_link_options(${_WRAPPER_MODULE_NAME}
    PRIVATE "-Wl,-force_load,$<TARGET_FILE:_CSP>"
  )
endif()

# Force /MD (Release runtime) to match CSP DLL runtime library settings
# This is an unexpected choice from CSP's end. I hope this changes.
# https://github.com/magnopus-opensource/connected-spaces-platform/blob/15f530fdd7a8b1782772338eee637e989057c815/premake5_helpers.lua#L124
if(MSVC)
  target_compile_options(${_WRAPPER_MODULE_NAME} PRIVATE
    $<$<CONFIG:Debug>:/MD>
    $<$<CONFIG:Release>:/MD>
  )
endif()

# macOS rpath
# Ensure the wrapper can resolve @rpath by looking in its own folder at runtime.
# This makes the dependent lookup land on the sibling dylib.
set_target_properties(${_WRAPPER_MODULE_NAME} PROPERTIES
  MACOSX_RPATH ON
  INSTALL_RPATH "@loader_path"
  BUILD_RPATH "@loader_path"
)

# iOS signing disabled
# When building for ios, it will complain, but we don't need to sign (I think...) because we're just a static library
# (Dynamic would need to be signed ... is this why we don't support dynamic on ios?)
set_target_properties(${_WRAPPER_MODULE_NAME} PROPERTIES
  XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
  XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO"
)

# Diagnostics
get_target_property(_CSP_TYPE _CSP TYPE)
message(STATUS "CSP target type: ${_CSP_TYPE}")

include(cmake/PackageInstall.cmake)

# If desired, automatically copy the generated code and libs into the Unity test project.
if(COPY_OUTPUT_TO_UNITY_TEST_PROJECT)
  message(STATUS "\nStarting the copy of latest generated C# code and libraries to the Unity test project...")
  include(cmake/InstallToUnityProject.cmake)
endif()