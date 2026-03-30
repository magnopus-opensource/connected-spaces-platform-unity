# This script is called by CMake -P to perform cross-platform text replacement
file(READ "${FILE_TO_PATCH}" CONTENT)

# Replace the quoted placeholder with the unquoted variable name
string(REPLACE "${OLD_STR}" "${NEW_STR}" REPLACED_CONTENT "${CONTENT}")

file(WRITE "${FILE_TO_PATCH}" "${REPLACED_CONTENT}")