# ---------------- Package / Install ----------------

# In the future, this might want to produce something friendlier for CSharp,
# currently it ships the necessary .dll/.so's, as well as the .cs files that serve as includes.
# I'm not totally sure about the ecosystem. Do you ship .csproj files?

set(INSTALL_DIR "${CMAKE_SOURCE_DIR}/install" CACHE FILEPATH "Directory to install output .cs and shared libraries")

# Remove the install dir at install time so old artifacts don't hang around
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_DIR}\")
")

# Primary install of the generated wrapper binary
install(
  TARGETS ${_WRAPPER_MODULE_NAME}
  RUNTIME DESTINATION "${INSTALL_DIR}/bin" # .exe / .dll on Windows
  LIBRARY DESTINATION "${INSTALL_DIR}/lib" # .so / .dylib on Unix
  ARCHIVE DESTINATION "${INSTALL_DIR}/lib" # .lib static import libraries
)

# Install debug symbols of the wrapper binary in addition
if(MSVC)
  install(
    FILES $<TARGET_PDB_FILE:${_WRAPPER_MODULE_NAME}>
    DESTINATION "${INSTALL_DIR}/bin"
    CONFIGURATIONS Debug RelWithDebInfo #RelWithDebInfo doesn't exist, but it'll want to be here when it does.
  )
endif()

# /cs generated dir, the files you actually work with in Csharp.
install(
  DIRECTORY "${_GEN_CS_DIR}/"
  DESTINATION "${INSTALL_DIR}/include"
)

# Extra C# files to install
cmake_path(APPEND _tmp_extra_cs_path
    "${CMAKE_BINARY_DIR}"
    ".."
    "extra"
    "cs"
)
set(CSP_EXTRA_CS_PATH "${_tmp_extra_cs_path}"
    CACHE PATH "Path to extra C# files to install"
)
install(
  DIRECTORY "${CSP_EXTRA_CS_PATH}/"
  DESTINATION "${INSTALL_DIR}/include"
)

# The actual underlying CSP library, needs to sit alongside the bindings.
# Including this makes this a complete artifact.
if (BUILD_SHARED_LIBS)
  install(
    FILES $<TARGET_FILE:_CSP>
    DESTINATION ${INSTALL_DIR}/bin
  )
endif()

# Finally the underlying CSP's debug symbols on windows platforms (no pdb equivalent on unix).
# TARGET_PDB_FILE is not available for imported targets (why though?)
# So do it more explicitly.
if(MSVC AND BUILD_SHARED_LIBS)
  install(FILES "${_CSP_LIB_DIR}/ConnectedSpacesPlatform_D.pdb"
          DESTINATION "${INSTALL_DIR}/bin"
          CONFIGURATIONS Debug)

  install(FILES "${_CSP_LIB_DIR}/ConnectedSpacesPlatform.pdb"
          DESTINATION "${INSTALL_DIR}/bin"
          CONFIGURATIONS RelWithDebInfo)
elseif(APPLE AND BUILD_SHARED_LIBS)
    # This is redundant I think, CSP could build DWARF with debug symbols embedded, I don't think dSYMs are the norm?
    install(DIRECTORY "${_CSP_LIB_DIR}/libConnectedSpacesPlatform_D.dylib.dSYM"
            DESTINATION "${INSTALL_DIR}/bin"
            CONFIGURATIONS Debug)
          
    install(DIRECTORY "${_CSP_LIB_DIR}/libConnectedSpacesPlatform.dylib.dSYM"
            DESTINATION "${INSTALL_DIR}/bin"
            CONFIGURATIONS RelWithDebInfo)
endif()