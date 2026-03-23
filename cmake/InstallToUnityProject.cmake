# Path to the folder of the Unity project where the generated CSP code and libs will be copied to.

cmake_path(APPEND CSP_LIB_UNITY_DIR
    "${CMAKE_BINARY_DIR}"
    ".."
    "UnityProject"
    "CspUnityTests"
    "Assets"
    "Plugins"
)
set(CSP_LIB_UNITY_DIR "${CSP_LIB_UNITY_DIR}"
    CACHE PATH "Path to Unity CSP plugin directory"
)

cmake_path(APPEND UNITY_EDITOR_SCRIPTS_DIR
    "${CMAKE_BINARY_DIR}"
    ".."
    "UnityProject"
    "CspUnityTests"
    "Assets"
    "Plugins"
    "Editor"
)
set(UNITY_EDITOR_SCRIPTS_DIR "${UNITY_EDITOR_SCRIPTS_DIR}"
    CACHE PATH "Path to Unity Editor scripts directory"
)

# The folder containing extra files we need to copy into the Unity project (such as asmdef and build scripts).
cmake_path(APPEND _tmp_extra_Unity_files_path
    "${CMAKE_BINARY_DIR}"
    ".."
    "UnityProject"
    "extra"
)
set(EXTRA_UNITY_FILES_PATH "${_tmp_extra_Unity_files_path}"
    CACHE FILEPATH "Path to Unity extra files"
)

# The asmdef file that will be used to establish the build settings for the generated CSP code and libs
cmake_path(APPEND _tmp_asmdef_path
    "${EXTRA_UNITY_FILES_PATH}"
    "ConnectedSpacesPlatform.Unity.Core.asmdef"
)
set(CSP_ASMDEF_PATH "${_tmp_asmdef_path}"
    CACHE FILEPATH "Path to ConnectedSpacesPlatform Unity .asmdef file"
)

message(STATUS "CSP_LIB_UNITY_DIR='${CSP_LIB_UNITY_DIR}'")
message(STATUS "UNITY_EDITOR_SCRIPTS_DIR='${UNITY_EDITOR_SCRIPTS_DIR}'")
message(STATUS "CSP_ASMDEF_PATH='${CSP_ASMDEF_PATH}'")

# Base folder inside Unity project
set(UNITY_CSP_ROOT "${CSP_LIB_UNITY_DIR}")

if(APPLE)
    if(IOS)
        set(UNITY_PLATFORM_DIR "${UNITY_CSP_ROOT}/iOS")
    elseif(CMAKE_SYSTEM_NAME STREQUAL "visionOS")
        set(UNITY_PLATFORM_DIR "${UNITY_CSP_ROOT}/visionOS")
    else()
        # macOS (Intel or Apple Silicon)
        if(CMAKE_OSX_ARCHITECTURES MATCHES "arm64")
            set(UNITY_PLATFORM_DIR "${UNITY_CSP_ROOT}/macOS")
        else()
            set(UNITY_PLATFORM_DIR "${UNITY_CSP_ROOT}/macOSIntel")
        endif()
    endif()

elseif(ANDROID)
    # Android splits by ABI
    set(UNITY_PLATFORM_DIR "${UNITY_CSP_ROOT}/android/${CMAKE_ANDROID_ARCH_ABI}")
        
    # Validate supported ABIs
    set(SUPPORTED_ABIS "arm64-v8a" "armeabi-v7a" "x86_64")
    if(NOT CMAKE_ANDROID_ARCH_ABI IN_LIST SUPPORTED_ABIS)
        message(FATAL_ERROR "Unsupported Android ABI: ${CMAKE_ANDROID_ARCH_ABI}")
    endif()

elseif(WIN32)
    set(UNITY_PLATFORM_DIR "${UNITY_CSP_ROOT}/windows")

elseif(UNIX AND NOT APPLE)
    #set(UNITY_PLATFORM_DIR "${UNITY_CSP_ROOT}/linux")
    message(FATAL_ERROR "Unsupported linux platform for Unity plugin install.")

else()
    message(FATAL_ERROR "Unsupported platform for Unity plugin install.")
endif()

message(STATUS "Unity plugin output -> ${UNITY_PLATFORM_DIR}")

# Run these operations during install:
#   cmake --install build --config Debug
install(CODE "
    message(\"Installing CSP to Unity plugin folder: ${UNITY_PLATFORM_DIR}\")
    
    message(\"Deleting previous Unity generated code and libraries...\")
    file(REMOVE_RECURSE \"${UNITY_PLATFORM_DIR}\")
    file(REMOVE_RECURSE \"${UNITY_CSP_ROOT}/include\")

    file(MAKE_DIRECTORY \"${UNITY_PLATFORM_DIR}\")
    file(MAKE_DIRECTORY \"${UNITY_CSP_ROOT}/include\")
    
    message(\"Deleting Unity editor scripts to replace them with latest ones...\")
    file(REMOVE_RECURSE \"${UNITY_EDITOR_SCRIPTS_DIR}\")

    # Copy C# SWIG bindings
    message(\"Copying SWIG-generated C#...\")
    file(COPY \"${INSTALL_DIR}/include/\" DESTINATION \"${UNITY_CSP_ROOT}/include\")

    # Copy platform-specific native library and binaries
    if(EXISTS \"${INSTALL_DIR}/bin\")
        message(\"Copying binaries for Unity platform...\")
        file(COPY \"${INSTALL_DIR}/bin/\" DESTINATION \"${UNITY_PLATFORM_DIR}\")
    endif()
    if(EXISTS \"${INSTALL_DIR}/lib\")
        message(\"Copying libraries for Unity platform...\")
        file(COPY \"${INSTALL_DIR}/lib/\" DESTINATION \"${UNITY_PLATFORM_DIR}\")
    endif()
    
    # Copy asmdef
    message(\"Copying asmdef...\")
    file(COPY \"${CSP_ASMDEF_PATH}\" DESTINATION \"${UNITY_CSP_ROOT}/include\")
    
    # Copy Unity editor scripts
    message(\"Copying Unity editor scripts...\")
    file(MAKE_DIRECTORY \"${UNITY_EDITOR_SCRIPTS_DIR}\")
    file(COPY \"${EXTRA_UNITY_FILES_PATH}/Editor\" DESTINATION \"${UNITY_CSP_ROOT}\")
    file(COPY \"${EXTRA_UNITY_FILES_PATH}/Editor.meta\" DESTINATION \"${UNITY_CSP_ROOT}\")
")