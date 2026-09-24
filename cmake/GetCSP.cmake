include_guard(GLOBAL)

# Fetch the prebuilt CSP package for the requested configuration.
#
# CSP release artifacts use: # <platform>-<build-type>-<linkage>.zip
#
# Debug consumer builds intentionally use the CSP RelWithDebInfo package,
# as CSP Debug packages use the debug C++ runtime, which Unity cannot consume.
option(CSP_USE_SYSTEM_PACKAGE "Use a CSP package already discoverable by CMake instead of downloading the pinned version" OFF)

if(CSP_USE_SYSTEM_PACKAGE)
    message(STATUS "Using CSP package provided by the system/CMAKE_PREFIX_PATH")
    find_package(CSP CONFIG REQUIRED)
else()
    # Specify the CSP version we want to use.
    set(CSP_TARGET_VERSION "999.999.9999" CACHE STRING "The CSP release version to download")

    # Determine CSP platform
    if(WIN32)
        set(_CSP_PLATFORM "windows")
    elseif(APPLE)
        if(IOS)
            set(_CSP_PLATFORM "ios")
        else()
            set(_CSP_PLATFORM "macos")
        endif()
    elseif(ANDROID)
        set(_CSP_PLATFORM "android")
    elseif(UNIX)
        set(_CSP_PLATFORM "linux")
    else()
        message(FATAL_ERROR "Unsupported platform for CSP")
    endif()

    # Determine linkage
    if(BUILD_SHARED_LIBS)
        set(_CSP_LINKAGE "shared")
    else()
        set(_CSP_LINKAGE "static")
    endif()

    # Determine build type
    if(DEFINED CSP_BUILD_TYPE AND NOT CSP_BUILD_TYPE STREQUAL "")
        set(_CSP_CONSUMER_BUILD_TYPE "${CSP_BUILD_TYPE}")
    elseif(DEFINED CMAKE_BUILD_TYPE AND NOT CMAKE_BUILD_TYPE STREQUAL "")
        set(_CSP_CONSUMER_BUILD_TYPE "${CMAKE_BUILD_TYPE}")
    else()
        message(FATAL_ERROR
            "No build type specified. "
            "Set CMAKE_BUILD_TYPE for single-config generators or "
            "CSP_BUILD_TYPE for multi-config generators."
        )
    endif()

    if(_CSP_CONSUMER_BUILD_TYPE STREQUAL "Debug")
        # Unity cannot consume CSP built with the debug C++ runtime.
        set(_CSP_BUILD_TYPE "relwithdebinfo")
    elseif(_CSP_CONSUMER_BUILD_TYPE STREQUAL "RelWithDebInfo")
        set(_CSP_BUILD_TYPE "relwithdebinfo")
    elseif(_CSP_CONSUMER_BUILD_TYPE STREQUAL "Release")
        set(_CSP_BUILD_TYPE "release")
    elseif(_CSP_CONSUMER_BUILD_TYPE STREQUAL "MinSizeRel")
        set(_CSP_BUILD_TYPE "release")
    else()
        message(FATAL_ERROR "Unsupported build type '${_CSP_CONSUMER_BUILD_TYPE}'")
    endif()

    # Determine release artifact
    set(_CSP_RELEASE_ARTIFACT "${_CSP_PLATFORM}-${_CSP_BUILD_TYPE}-${_CSP_LINKAGE}.zip")

    # The asset filename does not contain the CSP version, so we need to store each 
    # version in a separate directory. This makes --skip-existing 
    # safe when switching between CSP versions.
    set(_CSP_DOWNLOAD_DIR "${_DEPS_DIR}/csp-download/${CSP_TARGET_VERSION}")
    set(_CSP_ARCHIVE "${_CSP_DOWNLOAD_DIR}/${_CSP_RELEASE_ARTIFACT}")

    # The CSP install package is extracted here.
    set(_CSP_INSTALL_DIR "${_DEPS_DIR}/connected-spaces-platform")

    # Find GitHub CLI 
    find_program(GH_EXECUTABLE gh)
    
    if(NOT GH_EXECUTABLE)
        message(FATAL_ERROR "GitHub CLI (gh) not found. Please install it and retry.")
    endif()

    file(MAKE_DIRECTORY "${_CSP_DOWNLOAD_DIR}")
    message(STATUS "Downloading CSP ${CSP_TARGET_VERSION}: ${_CSP_RELEASE_ARTIFACT}")

    # Download CSP
    execute_process(COMMAND "${GH_EXECUTABLE}" release download "${CSP_TARGET_VERSION}" --repo magnopus-opensource/connected-spaces-platform --pattern "${_CSP_RELEASE_ARTIFACT}" --skip-existing --dir "${_CSP_DOWNLOAD_DIR}" WORKING_DIRECTORY "${CMAKE_BINARY_DIR}" RESULT_VARIABLE _CSP_DOWNLOAD_RESULT)

    if(NOT _CSP_DOWNLOAD_RESULT EQUAL 0)
        message(FATAL_ERROR "CSP download failed with code ${_CSP_DOWNLOAD_RESULT}")
    endif()

    if(NOT EXISTS "${_CSP_ARCHIVE}")
        message(FATAL_ERROR "Expected CSP archive was not downloaded: ${_CSP_ARCHIVE}")
    endif()

    # Extract CSP
    message(STATUS "Extracting ${_CSP_ARCHIVE} to ${_CSP_INSTALL_DIR}")

    # Prevent stale files from a previous package.
    file(REMOVE_RECURSE "${_CSP_INSTALL_DIR}")
    file(MAKE_DIRECTORY "${_CSP_INSTALL_DIR}")
    file(ARCHIVE_EXTRACT INPUT "${_CSP_ARCHIVE}" DESTINATION "${_CSP_INSTALL_DIR}")

    # Make CSP discoverable by CMake
    list(PREPEND CMAKE_PREFIX_PATH "${_CSP_INSTALL_DIR}")
    find_package(CSP CONFIG REQUIRED PATHS "${_CSP_INSTALL_DIR}" NO_CMAKE_FIND_ROOT_PATH)
endif()