#!/usr/bin/env bash
# git clean filter: strip a work tool's managed block from a markdown file on its way into the
# index, so this PUBLIC dotfiles repo never receives it.
#
# The installer that owns the block rewrites it on every update, so this must run on every
# stage rather than once. Clean-only, no smudge: the installer is what restores the block in
# the working tree, and a smudge counterpart would fight it.
#
# The marker token lives in the untracked ../private.env, because this script IS tracked in a
# public repo and hardcoding the token would leak what the filter exists to hide.
#
# Fails CLOSED. Registered with filter.<name>.required=true, so a non-zero exit aborts the
# stage instead of letting git fall back to the unfiltered original.
set -uo pipefail

ENV_FILE="${YADM_PRIVATE_ENV:-$HOME/.config/yadm/private.env}"

if [ ! -r "$ENV_FILE" ]; then
  echo "strip-managed-block: missing $ENV_FILE, refusing to stage unfiltered content" >&2
  exit 1
fi

# shellcheck source=/dev/null
. "$ENV_FILE"

if [ -z "${MANAGED_BLOCK_MARKER:-}" ]; then
  echo "strip-managed-block: MANAGED_BLOCK_MARKER unset in $ENV_FILE" >&2
  exit 1
fi

sed "/<!-- BEGIN ${MANAGED_BLOCK_MARKER}/,/<!-- END ${MANAGED_BLOCK_MARKER} -->/d" |
  # Collapse the blank-line run the deleted block leaves behind, so the committed file does not
  # churn a whitespace-only diff each time the block moves.
  awk 'BEGIN { blanks = 0 }
       /^[[:space:]]*$/ { blanks++; next }
       { while (blanks > 0) { print ""; blanks-- } print }
       END { if (blanks > 0) print "" }'
