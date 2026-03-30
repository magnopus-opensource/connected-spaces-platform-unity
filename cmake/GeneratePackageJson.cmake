# cmake/GeneratePackageJson.cmake
# Usage: cmake -D TEMPLATE=... -D OUTPUT=... -D VERSION=... -P cmake/GeneratePackageJson.cmake

# Read the template
file(READ "${TEMPLATE}" CONTENT)

# Replace the placeholder
string(REPLACE "VERSION_PLACEHOLDER" "${VERSION}" UPDATED_CONTENT "${CONTENT}")

# Write the final package.json
file(WRITE "${OUTPUT}" "${UPDATED_CONTENT}")