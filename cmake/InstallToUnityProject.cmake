# Path to the folder of the Unity project where the generated CSP code and libs will be copied to.
# 1 - Build the path safely
cmake_path(APPEND CSP_LIB_UNITY_DIR
    "${CMAKE_BINARY_DIR}"
    ".."
    "UnityProject"
    "CspUnityTests"
    "Assets"
    "Plugins"
)
# 2 - Cache the result
set(CSP_LIB_UNITY_DIR "${CSP_LIB_UNITY_DIR}"
    CACHE PATH "Path to Unity CSP plugin directory"
)

# The asmdef file that will be used to establish the build settings for the generated CSP code and libs
# 1 - Build the path safely
cmake_path(APPEND _tmp_asmdef_path
    "${CMAKE_BINARY_DIR}"
    ".."
    "UnityProject"
    "ConnectedSpacesPlatform.Unity.Core.asmdef"
)
# 2 - Cache the result
set(CSP_ASMDEF_PATH "${_tmp_asmdef_path}"
    CACHE FILEPATH "Path to ConnectedSpacesPlatform Unity .asmdef file"
)

message(STATUS "CSP_LIB_UNITY_DIR='${CSP_LIB_UNITY_DIR}'")
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
")