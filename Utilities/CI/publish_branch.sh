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
# 3. Securely syncs with the remote branch (or creates an orphan if new).
# 4. Clears the working directory (preserving the .git folder).
# 5. Restores the staged source files, commits (if changes exist), tags, and pushes.
#
# USAGE:
# bash Utilities/CI/publish_branch.sh <SOURCE_DIR> <TARGET_BRANCH> <VERSION> [EXCLUDE_DIR]
# Example: bash Utilities/CI/publish_branch.sh "DotNet" "release/dotnet" "v0.0.2" "libs"
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
# Use ls-remote to check if the branch actually exists on the remote repository
if git ls-remote --exit-code --heads origin $TARGET_BRANCH >/dev/null 2>&1; then
    echo "Branch $TARGET_BRANCH exists on remote. Syncing to remote tip..."
    # Fetch the exact remote tip into FETCH_HEAD
    git fetch origin $TARGET_BRANCH
    # Force the local branch to perfectly match the remote tip
    git checkout -B $TARGET_BRANCH FETCH_HEAD
else
    echo "Branch $TARGET_BRANCH does not exist. Creating orphan branch..."
    git checkout --orphan $TARGET_BRANCH
fi

echo "Cleaning working directory..."
git rm -rf . --ignore-unmatch > /dev/null
# Delete all files/folders EXCEPT .git to avoid "Directory not empty" errors
ls -A | grep -v "^.git$" | xargs rm -rf

echo "Restoring source files..."
mv ../dist-temp/* .

echo "Checking for changes to commit..."
git add .

# Safely check if the staging area has any actual changes
if git diff --staged --quiet; then
    echo "No changes detected for $TARGET_BRANCH. Working tree is identical."
    echo "Skipping commit, but proceeding to tag to maintain lockstep versioning."
else
    git commit -m "Release $VERSION"
    git push origin $TARGET_BRANCH
fi

# Note: Extracts just the 'dotnet' part from 'release/dotnet' for the tag
# ALWAYS tag the branch to ensure Unity and DotNet stay in lockstep
TAG_NAME="${TARGET_BRANCH##*/}/$VERSION" 
git tag -f "$TAG_NAME"
git push -f origin "$TAG_NAME"