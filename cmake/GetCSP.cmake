# Fetch CSP. If CSP were cmake this would be hugely simplified and more robust.
# Windows only right now, making this cross platform is going to be a pain.

include_guard(GLOBAL)

# Build the GLOB used to fetch the specific CSP library depending on what platform we're building on.
# This is a workaround for CSP not being cmake native, need to figure this out ourselves.
if(WIN32)
    if(BUILD_SHARED_LIBS)
        set(_CSP_RELEASE_ARTIFACT_PATTERN "*Win64*.zip")
    else()
         message(FATAL_ERROR "Cannot build for windows statically, CSP does not provide these binaries.")
    endif()
elseif(APPLE)
    # iOS vs macOS
    if(IOS)
        if(BUILD_SHARED_LIBS)
            message(FATAL_ERROR "Cannot build for iOS with shared libs, CSP does not provide these binaries.")
        else()
            set(_CSP_RELEASE_ARTIFACT_PATTERN "*iOS*.tar.gz")
        endif()
    else()
        if(BUILD_SHARED_LIBS)
            set(_CSP_RELEASE_ARTIFACT_PATTERN "*macOS.shared*.tar.gz")
        else()
            set(_CSP_RELEASE_ARTIFACT_PATTERN "*macOS.static*.tar.gz")
        endif()
    endif()
elseif(ANDROID)
    if(BUILD_SHARED_LIBS)
        set(_CSP_RELEASE_ARTIFACT_PATTERN "*Android*.zip")
    else()
         message(FATAL_ERROR "Cannot build for android statically, CSP does not provide these binaries.")
    endif()
elseif(UNIX)
    message(FATAL_ERROR "Cannot build for Unix, CSP does not provide these binaries.")
endif()

# If we've set a CSP_ROOT_DIR ourselves, don't bother downloading, just use it
if(NOT DEFINED CSP_ROOT_DIR)
  set(CSP_ROOT_DIR "${_DEPS_DIR}/connected-spaces-platform" CACHE PATH "Path to Connected Spaces Platform root")

  # This is necessary to find the specific CSP release version we are looking for.
  # This dependency could be removed if CSP omitted the build number from its release naming.
  # Then we could pin to a CSP_RELEASE_NUMBER variable, and deduce the URL directly.
  find_program(GH_EXECUTABLE gh)
  if(NOT GH_EXECUTABLE)
      message(FATAL_ERROR "GitHub CLI (gh) not found. Please install it and retry. (https://cli.github.com/)")
  endif()

  # Specify the CSP version we want to use for the SWIG build
  set(CSP_TARGET_VERSION "v6.47.0" CACHE STRING "The CSP release version to download")
  message(STATUS "Downloading CSP release version: '${CSP_TARGET_VERSION}'")

  # Download specific CSP version using a Git tag
  execute_process(
      COMMAND gh release download ${CSP_TARGET_VERSION} --repo magnopus-opensource/connected-spaces-platform --pattern ${_CSP_RELEASE_ARTIFACT_PATTERN} --skip-existing --dir ${_DEPS_DIR}
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
      RESULT_VARIABLE res
  )
  if(res)
      message(FATAL_ERROR "CSP Download failed with code ${res}")
      return()
  endif()

  # Unzip it (we don't know the precise name)
  file(GLOB _CSP_ZIP_FILES_LIST "${_DEPS_DIR}/${_CSP_RELEASE_ARTIFACT_PATTERN}")
  list(LENGTH _CSP_ZIP_FILES_LIST _CSP_ZIP_COUNT)
  if(NOT _CSP_ZIP_COUNT EQUAL 1)
      message(FATAL_ERROR "Could not find CSP zip file when unzipping")
  endif()

  # Cmake syntax eh, we're just using glob to find the file, but it's a list, should just be 1-big, get it.
  list(GET _CSP_ZIP_FILES_LIST 0 _CSP_ZIP_FILE)
  message("Unzipping ${_CSP_ZIP_FILE} to ${CSP_ROOT_DIR}")

  file(MAKE_DIRECTORY ${CSP_ROOT_DIR})
  execute_process(
      COMMAND ${CMAKE_COMMAND} -E tar xzf "${_CSP_ZIP_FILE}"
      WORKING_DIRECTORY ${CSP_ROOT_DIR}
  )

  # Argh! CSP zips its include dir for _some_ reason
  execute_process(
      COMMAND ${CMAKE_COMMAND} -E tar xzf "${CSP_ROOT_DIR}/include/include.zip"
      WORKING_DIRECTORY ${CSP_ROOT_DIR}/include
  )
else()
  message(STATUS "Using CSP_ROOT_DIR=${CSP_ROOT_DIR}, CSP download skipped.")
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(_CSP_NAME "libConnectedSpacesPlatform_D.dylib")
else()
    set(_CSP_NAME "libConnectedSpacesPlatform.dylib")
endif()
set(_CSP_INCLUDE_DIR "${CSP_ROOT_DIR}/include")
set(_CSP_LIB_DIR "${CSP_ROOT_DIR}/lib")
set(_CSP_BINARY_PATH  "${_CSP_LIB_DIR}/${_CSP_NAME}")

message(STATUS "CSP_ROOT_DIR='${CSP_ROOT_DIR}'")
message(STATUS "_CSP_INCLUDE_DIR='${_CSP_INCLUDE_DIR}'")


if (APPLE AND BUILD_SHARED_LIBS)
    # Patch the install_name so it can be loaded from anywhere.
    # I think CSP should probably do this upstream, rather than insisting on /usr/local
    # WARNING. This invalidates codesigning, so we resign
    add_custom_target(_PATCH_CSP_INSTALL_NAME
        COMMAND install_name_tool -id "@rpath/${_CSP_NAME}" "${_CSP_BINARY_PATH}"
        # Ad-hoc sign (the - after the s)
        COMMAND codesign -s - --timestamp=none --force "${_CSP_BINARY_PATH}"
        VERBATIM)
endif()

# Export a target
if(BUILD_SHARED_LIBS)
    add_library(_CSP SHARED IMPORTED GLOBAL)
else()
    add_library(_CSP STATIC IMPORTED GLOBAL)
endif()

if(WIN32)
    set_target_properties(_CSP PROPERTIES
        IMPORTED_IMPLIB_RELEASE "${_CSP_LIB_DIR}/ConnectedSpacesPlatform.lib"
        IMPORTED_IMPLIB_DEBUG "${_CSP_LIB_DIR}/ConnectedSpacesPlatform_D.lib"
        IMPORTED_LOCATION_RELEASE "${_CSP_LIB_DIR}/ConnectedSpacesPlatform.dll"
        IMPORTED_LOCATION_DEBUG "${_CSP_LIB_DIR}/ConnectedSpacesPlatform_D.dll"
        INTERFACE_INCLUDE_DIRECTORIES "${_CSP_INCLUDE_DIR}"
    )
elseif(APPLE)
    # We're braching on 2 things here (ios is static, macos shared), 
    # so build the name to avoid massive branching later
    set(_LIB_SUFFIX "")
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(_LIB_SUFFIX "_D")
    endif()

    if(BUILD_SHARED_LIBS)
        set(_LIB_EXT ".dylib")
    else()
        set(_LIB_EXT ".a")
    endif()

    set(CSP_APPLE_LIBRARY_NAME "libConnectedSpacesPlatform${_LIB_SUFFIX}${_LIB_EXT}")

    # It's not normal to do _D on unix platforms, CSP should change this. CMake dosen't understand very well (Can't use the LOCATION_DEBUG option, have to branch above)
    set_target_properties(_CSP PROPERTIES
        IMPORTED_LOCATION "${_CSP_LIB_DIR}/${CSP_APPLE_LIBRARY_NAME}"
        INTERFACE_INCLUDE_DIRECTORIES "${_CSP_INCLUDE_DIR}"
    )

    if (NOT BUILD_SHARED_LIBS)
        # Static OpenSSL. CSP needs these. (crypto, ssl)
        add_library(_OpenSSL_crypto STATIC IMPORTED GLOBAL)
        set_target_properties(_OpenSSL_crypto PROPERTIES
            IMPORTED_LOCATION "${_CSP_LIB_DIR}/libcrypto.a"
        )

        add_library(_OpenSSL_ssl STATIC IMPORTED GLOBAL)
        set_target_properties(_OpenSSL_ssl PROPERTIES
            IMPORTED_LOCATION "${_CSP_LIB_DIR}/libssl.a"
            INTERFACE_LINK_LIBRARIES _OpenSSL_crypto
        )

        # If _CSP itself needs OpenSSL, express that once here:
        target_link_libraries(_CSP INTERFACE _OpenSSL_ssl)
    endif()

    if (BUILD_SHARED_LIBS)
        # Patch the install name on apple platforms, so the SWIG lib can load the CSP lib from adjacent to itself
        add_dependencies(_CSP _PATCH_CSP_INSTALL_NAME)
    endif()
else()
    # Unix, but for us right now, actually android
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set_target_properties(_CSP PROPERTIES
            IMPORTED_LOCATION "${_CSP_LIB_DIR}/libConnectedSpacesPlatform_D.so"
            INTERFACE_INCLUDE_DIRECTORIES "${_CSP_INCLUDE_DIR}"
        )
    else()
        set_target_properties(_CSP PROPERTIES
            IMPORTED_LOCATION "${_CSP_LIB_DIR}/libConnectedSpacesPlatform.so"
            INTERFACE_INCLUDE_DIRECTORIES "${_CSP_INCLUDE_DIR}"
        )
    endif()
endif()