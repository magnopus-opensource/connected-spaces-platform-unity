cmake_minimum_required(VERSION 3.28)
project(MyProj)

set(_DEPS_DIR "${CMAKE_BINARY_DIR}/_deps")

include(FetchContent)
include(cmake/Options.cmake)
include(cmake/GetSwig.cmake)

if(LEGACY_BUILD_SYSTEM)
  include(cmake/GetCSP.cmake)
  set(CSP_INCLUDE_DIR "${_CSP_INCLUDE_DIR}")
  set(_CSP_TARGET_NAME "_CSP")
  # Assume if we're building shared, then we're trying to build from a shared CSP
  # Not technically correct, the non-legacy build system provides a mechanism
  # to make the distinction as is proper.
  set(CSP_BUILT_SHARED ${BUILD_SHARED_LIBS})
else()
  find_package(CSP CONFIG REQUIRED)
  set(_CSP_TARGET_NAME "CSP::csp-lib")
  get_target_property(_CSP_LIB_DIR ${_CSP_TARGET_NAME} LOCATION)
  get_filename_component(_CSP_LIB_DIR "${_CSP_LIB_DIR}" DIRECTORY)
endif()

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

# SWIG requires literal strings for -dllimport. 
# To support dynamic platform switching in C#, we use a placeholder string 
# and post-process the generated PINVOKE class to replace it with a 
# reference to the 'LibName' constant defined in main.i.
# This allows us to change the dll name used by the dllimport depending on
# the targeted platform (see the LibName constant in main.i for more details). 
set(DLL_NAME_FOR_LINKING "DLL_NAME_FOR_LINKING_TO_BE_PATCHED")

# Preprocess CSP includes to guard the legacy wrapper gen NO_EXPORT declarations so they don't confuse us
if(GUARD_CSP_NO_EXPORTS)
    # Trim the CSP_NO_EXPORT stuff off so SWIG dosen't try to generate it
  find_package(Python3 REQUIRED COMPONENTS Interpreter)

  message("Guarding CSP include dir files from NO_EXPORT sections")

  set(CSP_FILTERED_INCLUDE_DIR "${CMAKE_BINARY_DIR}/csp_filtered_include")
  execute_process(
    COMMAND "${Python3_EXECUTABLE}"
            "${CMAKE_SOURCE_DIR}/Utilities/GuardNoExports/GuardNoExports.py"
            "${CSP_INCLUDE_DIR}"          
            "${CSP_FILTERED_INCLUDE_DIR}" 
      COMMAND_ERROR_IS_FATAL ANY)

  # Rebind Cmake state to point to the new filtered include dir
  set(CSP_INCLUDE_DIR "${CSP_FILTERED_INCLUDE_DIR}")
  set_target_properties(${_CSP_TARGET_NAME} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${CSP_FILTERED_INCLUDE_DIR}")
endif()

# Setup SWIG invocation.
# Setup as a custom target so code generation reruns on every build, rather than on every fresh configure.
# Means you don't need to reconfigure all the time, and are be able to change .i files and rebuild in your editor as you'd expect.
add_custom_target(SWIGCodegen ALL
  COMMAND ${CMAKE_COMMAND} -E remove_directory "${_GEN_CPP_DIR}" # Clean up first
  COMMAND ${CMAKE_COMMAND} -E remove_directory "${_GEN_CS_DIR}"
  COMMAND "${CMAKE_COMMAND}" -E make_directory "${_GEN_CPP_DIR}" "${_GEN_CS_DIR}"
  COMMAND "${SWIG_EXE}"
          -I${CSP_INCLUDE_DIR} # So we can #include CSP's .h files.
          -I${ROOT_I_DIR} # So we can %include our own .i files.
          -I${_INTERNAL_SWG_SEARCH_PATH_CSHARP} # C# search path for SWIG .i lib files. (This should be first as some are named the same)
          -I${_INTERNAL_SWG_SEARCH_PATH_GLOBAL} # Global search path for SWIG .i lib files.
          -c++ -csharp
          -module ${_WRAPPER_MODULE_NAME}
          -dllimport "${DLL_NAME_FOR_LINKING}"
          -outdir "${_GEN_CS_DIR}"
          -o "${_CPP_WRAPPER_OUT}"
          ${SWIG_UNITY_FLAG} # Optionally enable unity extensions
          ${THROW_EXCEPTION_ON_RESULTBASE_FAILURE_FLAG} # Optionally generate ThrowOnFailure code when ResultBase is returned with failure status code.
          -v # Still could be verboser ... There's other options if you need them
          "${_ROOT_I_FILE}"

  # Remove the quotes around the placeholder string, so that it is treated as a variable rather than a literal.
  # This converts [DllImport("DLL_NAME_FOR_LINKING_TO_BE_PATCHED")] -> [DllImport(LibName)]
  # Note: we use LibName here because that matches the variable in main.i
  COMMAND ${CMAKE_COMMAND} -E echo "Patching PInvoke attributes for cross-platform compatibility..."

  # Cross-platform replacement logic
  COMMAND ${CMAKE_COMMAND} -D "FILE_TO_PATCH=${_GEN_CS_DIR}/ConnectedSpacesPlatformDotNetPINVOKE.cs"
                           -D "OLD_STR=\"${DLL_NAME_FOR_LINKING}\""
                           -D "NEW_STR=ConnectedSpacesPlatformDotNetPINVOKE.LibName"
                           -P "${CMAKE_SOURCE_DIR}/cmake/PatchPInvoke.cmake"

  BYPRODUCTS "${_CPP_WRAPPER_OUT}"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
  VERBATIM
)

# The wrapper source is generated at build time; tell CMake not to expect it at configure time.
set_source_files_properties("${_CPP_WRAPPER_OUT}" PROPERTIES GENERATED TRUE)

# ---------------- Build SWIG Output ----------------
if (BUILD_SHARED_LIBS)
  add_library(${_WRAPPER_MODULE_NAME} SHARED "${_CPP_WRAPPER_OUT}")
else()
  add_library(${_WRAPPER_MODULE_NAME} STATIC "${_CPP_WRAPPER_OUT}")
endif()

# Force /MD (Release runtime) to match CSP DLL runtime library settings
# This is an unexpected choice from CSP's end. I hope this changes.
# https://github.com/magnopus-opensource/connected-spaces-platform/blob/15f530fdd7a8b1782772338eee637e989057c815/premake5_helpers.lua#L124
if(MSVC AND LEGACY_BUILD_SYSTEM)
  target_compile_options(${_WRAPPER_MODULE_NAME} PRIVATE
    $<$<CONFIG:Debug>:/MD>
    $<$<CONFIG:Release>:/MD>
  )
endif()

if (CSP_BUILT_SHARED)
  # Pretty important, make sure we're importing symbols. 
  # Otherwise you'll get duplicate template instances and such. Bad times.
  target_compile_definitions(${_WRAPPER_MODULE_NAME} PRIVATE USING_CSP_DLL)
endif()

# Make it so the wrapper module always builds after codegen happens
add_dependencies(${_WRAPPER_MODULE_NAME} SWIGCodegen)

set_target_properties(${_WRAPPER_MODULE_NAME} PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED YES
  POSITION_INDEPENDENT_CODE ON
  OUTPUT_NAME "${_WRAPPER_MODULE_NAME}" # ConnectedSpacesPlatform.dll/libConnectedSpacesPlatform.so
)

# Add CSP Target to our output library, this produces a final API that can use CSP.
target_link_libraries(${_WRAPPER_MODULE_NAME} PRIVATE ${_CSP_TARGET_NAME})

if(CMAKE_SYSTEM_NAME STREQUAL "iOS" OR CMAKE_SYSTEM_NAME STREQUAL "visionOS")
    # Additionally, on iOS and visionOS we have to force load the CSP static library because the dynamic lookup doesn't 
    # work with static libraries, and we don't have a choice but to use static libs on iOS.
    target_link_options(${_WRAPPER_MODULE_NAME} PRIVATE "-Wl,-force_load,$<TARGET_FILE:${_CSP_TARGET_NAME}>")
endif()

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

# Do not remove this install directive.
# Removing this causes Xcode "Undefined symbols for architecture arm64".
if(APPLE)
    if(CMAKE_SYSTEM_NAME STREQUAL "iOS" OR CMAKE_SYSTEM_NAME STREQUAL "visionOS")
        # Copy the original CSP libraries alongside the one we created via SWIG
        install(DIRECTORY "${_CSP_LIB_DIR}/"
                DESTINATION "${INSTALL_DIR}/lib")
    endif()
endif()

# If desired, automatically copy the generated code and libs into the Unity test project.
if(COPY_OUTPUT_TO_UNITY_TEST_PROJECT)
  message(STATUS "\nStarting the copy of latest generated C# code and libraries to the Unity test project...")
  include(cmake/InstallToUnityProject.cmake)
endif()