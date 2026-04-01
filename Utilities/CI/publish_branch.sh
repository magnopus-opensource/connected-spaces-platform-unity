#!/bin/bash
set -e

# ==============================================================================
# publish_branch.sh
#
# PURPOSE:
# This script safely pushes a specific directory of source code to a target 
# release branch (e.g., release/dotnet or release/unity). 
# 
# HOW IT WORKS:
# 1. Stages the target directory in a temporary folder outside the workspace.
# 2. Strips out heavy native binaries (like .dll or .so files) to prevent Git bloat.
# 3. Checks out an orphan/clean target branch.
# 4. Clears the working directory (preserving the .git folder).
# 5. Restores the staged source files, commits, tags, and pushes.
#
# USAGE:
# ./Utilities/CI/publish_branch.sh <SOURCE_DIR> <TARGET_BRANCH> <VERSION> [EXCLUDE_DIR]
# Example: ./Utilities/CI/publish_branch.sh "DotNet" "release/dotnet" "v1.0.0" "libs"
# ==============================================================================

SOURCE_DIR=$1
TARGET_BRANCH=$2
VERSION=$3
EXCLUDE_DIR=$4 

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

echo "Staging $SOURCE_DIR to temporary directory..."
mkdir -p ../dist-temp
cp -r $SOURCE_DIR/* ../dist-temp/

# Remove the heavy binaries before committing to Git
if [ -n "$EXCLUDE_DIR" ]; then 
    echo "Excluding $EXCLUDE_DIR from Git..."
    rm -rf ../dist-temp/$EXCLUDE_DIR 
fi

echo "Switching to $TARGET_BRANCH..."
git fetch origin $TARGET_BRANCH || true
git checkout $TARGET_BRANCH || git checkout --orphan $TARGET_BRANCH

echo "Cleaning working directory..."
git rm -rf . --ignore-unmatch > /dev/null
# Delete all files/folders EXCEPT .git to avoid "Directory not empty" errors
ls -A | grep -v "^.git$" | xargs rm -rf

echo "Restoring source files..."
mv ../dist-temp/* .

echo "Committing and pushing..."
git add .
git commit -m "Release $VERSION"
git push origin $TARGET_BRANCH

# Note: Extracts just the 'dotnet' part from 'release/dotnet' for the tag
TAG_NAME="${TARGET_BRANCH##*/}/$VERSION" 
git tag -f "$TAG_NAME"
git push origin "$TAG_NAME"