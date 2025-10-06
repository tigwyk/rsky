#!/bin/bash
set -eu pipefail

# Get GitHub event variables from environment
EVENT_NAME="${GITHUB_EVENT_NAME}"
PR_BASE_SHA="${PR_BASE_SHA:-}"
PR_HEAD_SHA="${PR_HEAD_SHA:-}"
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/stdout}"

# Function to convert array to JSON without jq dependency
array_to_json() {
  local array=("$@")
  local json="["
  local separator=""
  
  # Handle empty arrays
  if [ ${#array[@]} -eq 0 ]; then
    echo "[]"
    return
  fi
  
  for item in "${array[@]}"; do
    # Skip empty items
    if [[ -n "$item" ]]; then
      json="${json}${separator}\"${item}\""
      separator=","
    fi
  done
  
  json="${json}]"
  echo "$json"
}

# Extract all packages from Cargo.toml - improved parsing
echo "Extracting workspace members from Cargo.toml..."
WORKSPACE_MEMBERS=()

# Look for members section in Cargo.toml
if grep -q '\[workspace\]' Cargo.toml; then
  echo "Found [workspace] section in Cargo.toml"
  
  # Extract the members array content from between [ and ]
  MEMBERS_CONTENT=$(awk '/members.*=.*\[/,/\]/' Cargo.toml | sed 's/.*\[//; s/\].*//' | tr -d ' \n' | tr ',' '\n')
  
  # Parse each member, removing quotes and whitespace
  while IFS= read -r member; do
    # Remove quotes and whitespace
    member=$(echo "$member" | tr -d '"' | tr -d "'" | xargs)
    if [[ -n "$member" ]]; then
      WORKSPACE_MEMBERS+=("$member")
      echo "Added workspace member: $member"
    fi
  done <<< "$MEMBERS_CONTENT"
else
  # Fallback: Try to find any directory that contains a Cargo.toml file
  echo "No [workspace] section found, falling back to finding all directories with Cargo.toml..."
  while IFS= read -r dir; do
    # Skip the root Cargo.toml
    if [[ "$dir" != "./Cargo.toml" ]]; then
      pkg_dir=$(dirname "$dir")
      # Remove the leading ./ if present
      pkg_dir=${pkg_dir#./}
      WORKSPACE_MEMBERS+=("$pkg_dir")
    fi
  done < <(find . -name "Cargo.toml" -type f | sort)
fi

# If still empty, add some default Rust packages from the directory structure
if [ ${#WORKSPACE_MEMBERS[@]} -eq 0 ]; then
  echo "No workspace members found in Cargo.toml, using detected packages..."
  for dir in $(find . -maxdepth 1 -type d -name "rsky*"); do
    # Remove the leading ./
    dir=${dir#./}
    WORKSPACE_MEMBERS+=("$dir")
  done
fi

echo "Found workspace members: ${WORKSPACE_MEMBERS[*]}"

# Define packages to skip
SKIP_PACKAGES=("cypher/frontend" "cypher/backend" "rsky-pdsadmin")

# Check if core workflow files have changes (more selective than entire .github directory)
WORKFLOW_CHANGES=false
if [[ "$EVENT_NAME" == "pull_request" && -n "$PR_BASE_SHA" && -n "$PR_HEAD_SHA" ]]; then
    BASE_SHA=$(git merge-base "$PR_BASE_SHA" "$PR_HEAD_SHA" || echo "$PR_BASE_SHA")
    # Only trigger full rebuild if core workflow files change, not scripts
    if [[ -n "$(git diff --name-only "$BASE_SHA" "$PR_HEAD_SHA" -- .github/workflows/rust.yml 2>/dev/null || echo '')" ]]; then
        WORKFLOW_CHANGES=true
    fi
else
    # For push events, compare with the previous commit
    if [[ -n "$(git diff --name-only HEAD^ HEAD -- .github/workflows/rust.yml 2>/dev/null || echo '')" ]]; then
        WORKFLOW_CHANGES=true
    fi
fi

echo "Core workflow changes: $WORKFLOW_CHANGES"

# Get list of packages with changes
CHANGED_MEMBERS=()

if [[ "$WORKFLOW_CHANGES" == "true" ]]; then
    # If core workflows have changes, include all packages (except skipped ones)
    echo "Changes detected in core workflow files, including all packages"
    for pkg in "${WORKSPACE_MEMBERS[@]}"; do
        CHANGED_MEMBERS+=("$pkg")
    done
else
    # Otherwise, only include packages with changes
    DIFF_FILES=""
    if [[ "$EVENT_NAME" == "pull_request" && -n "$PR_BASE_SHA" && -n "$PR_HEAD_SHA" ]]; then
        BASE_SHA=$(git merge-base "$PR_BASE_SHA" "$PR_HEAD_SHA" || echo "$PR_BASE_SHA")
        DIFF_FILES=$(git diff --name-only "$BASE_SHA" "$PR_HEAD_SHA" 2>/dev/null || echo '')
    else
        # For push events, compare with the previous commit
        DIFF_FILES=$(git diff --name-only HEAD^ HEAD 2>/dev/null || echo '')
    fi

    echo "Changed files:"
    echo "$DIFF_FILES"

    for pkg in "${WORKSPACE_MEMBERS[@]}"; do
        if echo "$DIFF_FILES" | grep -q "^$pkg/"; then
            CHANGED_MEMBERS+=("$pkg")
            echo "Package with changes: $pkg"
        fi
    done
    
    # Additionally, check if workspace-level Cargo files changed
    if echo "$DIFF_FILES" | grep -q "^Cargo\\.\\(toml\\|lock\\)$"; then
        echo "Changes detected in workspace Cargo files"
        # Only add packages that don't already exist in CHANGED_MEMBERS
        for pkg in "${WORKSPACE_MEMBERS[@]}"; do
            # Check if this package is already in CHANGED_MEMBERS
            found=false
            for existing_pkg in "${CHANGED_MEMBERS[@]}"; do
                if [[ "$pkg" == "$existing_pkg" ]]; then
                    found=true
                    break
                fi
            done
            # If not found and this is a critical package, add it
            if [[ "$found" == "false" ]] && [[ "$pkg" =~ ^rsky-(common|crypto|identity|lexicon|syntax|repo)$ ]]; then
                CHANGED_MEMBERS+=("$pkg")
                echo "Added core dependency package: $pkg"
            fi
        done
    fi
fi

# Filter out packages to skip
FILTERED_MEMBERS=()
for pkg in "${CHANGED_MEMBERS[@]}"; do
    skip=false
    for skip_pkg in "${SKIP_PACKAGES[@]}"; do
        if [[ "$pkg" == "$skip_pkg" ]]; then
            skip=true
            break
        fi
    done
    if [[ "$skip" == "false" ]]; then
        FILTERED_MEMBERS+=("$pkg")
    fi
done

# Always include at least one default package if array is empty
if [ ${#FILTERED_MEMBERS[@]} -eq 0 ]; then
    echo "No workspace members with changes found, using default fallback"
    # Look for rsky-common as a safe default, or use the first Rust package
    if [[ -d "rsky-common" && -f "rsky-common/Cargo.toml" ]]; then
        FILTERED_MEMBERS+=("rsky-common")
    else
        # Find the first available Rust package
        for dir in "${WORKSPACE_MEMBERS[@]}"; do
            if [[ -d "$dir" && -f "$dir/Cargo.toml" ]]; then
                FILTERED_MEMBERS+=("$dir")
                break
            fi
        done
    fi
    
    # If still empty, use a hardcoded fallback
    if [ ${#FILTERED_MEMBERS[@]} -eq 0 ]; then
        echo "No valid workspace members found, using default package"
        # Use the first 'rsky-' directory as fallback
        for dir in rsky-*; do
            if [[ -d "$dir" && -f "$dir/Cargo.toml" ]]; then
                FILTERED_MEMBERS+=("$dir")
                break
            fi
        done
    fi
fi

# Debug output
echo "Final filtered members array length: ${#FILTERED_MEMBERS[@]}"
for i in "${!FILTERED_MEMBERS[@]}"; do
  echo "Member [$i]: '${FILTERED_MEMBERS[$i]}'"
done

# Convert to JSON array for matrix - without jq dependency
JSON_MEMBERS=$(array_to_json "${FILTERED_MEMBERS[@]}")
echo "workspace_members=$JSON_MEMBERS" >> "$GITHUB_OUTPUT"
echo "Found workspace members to process: $JSON_MEMBERS"
