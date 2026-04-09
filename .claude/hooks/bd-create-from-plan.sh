#!/bin/bash
# Parse a scope+plan doc and create bd issues with dependencies.
# Usage: bd-create-from-plan.sh <path-to-scope-doc>
#
# Expects the doc to have sections like:
#   #### PR 1: Name
#   - [ ] Task 1 — description
#   - [ ] Task 2 — description
#   #### PR 2: Name
#   - [ ] Task 3 — description

set -euo pipefail

SCOPE_DOC="${1:?Usage: bd-create-from-plan.sh <path-to-scope-doc>}"

if [ ! -f "$SCOPE_DOC" ]; then
  echo "Error: File not found: $SCOPE_DOC" >&2
  exit 1
fi

# Extract the feature name from the first heading
FEATURE_NAME=$(head -5 "$SCOPE_DOC" | grep '^# ' | head -1 | sed 's/^# //')

echo "Creating bd issues from: $SCOPE_DOC"
echo "Feature: $FEATURE_NAME"
echo "---"

CURRENT_PR=""
PREV_PR_LAST_ID=""
CURRENT_PR_IDS=()
ALL_IDS=()

while IFS= read -r line; do
  # Detect PR section headers: #### PR N: Name
  if echo "$line" | grep -qE '^#{1,4} PR [0-9]+:'; then
    # Save previous PR's last ID for dependency chaining
    if [ ${#CURRENT_PR_IDS[@]} -gt 0 ]; then
      PREV_PR_LAST_ID="${CURRENT_PR_IDS[-1]}"
    fi
    CURRENT_PR=$(echo "$line" | sed 's/^#* //')
    CURRENT_PR_IDS=()
    echo ""
    echo "== $CURRENT_PR =="
    continue
  fi

  # Detect task lines: - [ ] Task — description
  if echo "$line" | grep -qE '^\s*-\s*\[\s*\]'; then
    # Extract task title and description
    TASK_TEXT=$(echo "$line" | sed 's/^\s*-\s*\[\s*\]\s*//')
    # Split on " — " to get title vs description
    TASK_TITLE=$(echo "$TASK_TEXT" | sed 's/ — .*//')
    TASK_DESC="$TASK_TEXT"

    # Build full description with context
    FULL_DESC="$TASK_DESC

Part of: $FEATURE_NAME
PR: ${CURRENT_PR:-unspecified}
Source: $SCOPE_DOC"

    # Create the bd issue (single line to avoid permission issues)
    RESULT=$(bd create --title="$TASK_TITLE" --type=task --priority=2 2>&1)
    ISSUE_ID=$(echo "$RESULT" | grep -oE 'conductor-[a-z0-9]+' | head -1)

    if [ -n "$ISSUE_ID" ]; then
      # Update with full description separately
      bd update "$ISSUE_ID" --description="$FULL_DESC" 2>/dev/null
      echo "  Created: $ISSUE_ID — $TASK_TITLE"
      CURRENT_PR_IDS+=("$ISSUE_ID")
      ALL_IDS+=("$ISSUE_ID")

      # If this is the first task of a new PR and previous PR had tasks,
      # make this task depend on the last task of the previous PR
      if [ ${#CURRENT_PR_IDS[@]} -eq 1 ] && [ -n "$PREV_PR_LAST_ID" ]; then
        bd dep add "$ISSUE_ID" "$PREV_PR_LAST_ID" 2>/dev/null
        echo "    └── depends on $PREV_PR_LAST_ID (previous PR)"
      fi
    else
      echo "  ERROR creating issue: $RESULT" >&2
    fi
  fi
done < "$SCOPE_DOC"

echo ""
echo "---"
echo "Created ${#ALL_IDS[@]} issues: ${ALL_IDS[*]}"
echo "Run 'bd ready' to see what's unblocked."
