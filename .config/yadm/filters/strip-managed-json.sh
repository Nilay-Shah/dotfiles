#!/usr/bin/env bash
# git clean filter: strip a work tool's entries from Claude Code's settings.json on its way into
# the index, so this PUBLIC dotfiles repo never receives internal hook paths or tool names.
#
# Unlike the markdown block, the installer merges these entries *into* existing arrays instead of
# writing a delimited region, so this matches on content: permission strings mentioning the
# marker, and hook commands pointing at the marked checkout. Matcher groups left with no hooks
# are dropped, then hook events left with no groups.
#
# The marker token lives in the untracked ../private.env, because this script IS tracked in a
# public repo.
#
# Fails CLOSED on anything that would risk leaking (missing env, missing jq, jq error) since it
# is registered with filter.<name>.required=true. The one deliberate pass-through is input that
# is not valid JSON: there is nothing to strip and nothing to leak, and refusing would block
# staging on a file the editor is mid-write on.
set -uo pipefail

ENV_FILE="${YADM_PRIVATE_ENV:-$HOME/.config/yadm/private.env}"

if [ ! -r "$ENV_FILE" ]; then
  echo "strip-managed-json: missing $ENV_FILE, refusing to stage unfiltered content" >&2
  exit 1
fi

# shellcheck source=/dev/null
. "$ENV_FILE"

# Wider than the block marker on purpose: sibling tooling shares the prefix but not the whole
# token, so matching the exact block marker here would silently miss those entries.
MATCH="${CONTENT_MATCH_REGEX:-${MANAGED_BLOCK_MARKER:-}}"

if [ -z "$MATCH" ]; then
  echo "strip-managed-json: neither CONTENT_MATCH_REGEX nor MANAGED_BLOCK_MARKER set in $ENV_FILE" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "strip-managed-json: jq not found, refusing to stage unfiltered content" >&2
  exit 1
fi

input="$(cat)"

# Not JSON at all: nothing to strip, so pass through rather than block the stage.
if ! printf '%s' "$input" | jq -e . >/dev/null 2>&1; then
  printf '%s' "$input"
  exit 0
fi

if ! filtered="$(printf '%s' "$input" | jq --indent 2 --arg marker "$MATCH" '
  def is_marked: (. // "") | tostring | test($marker; "i");

  (if (.permissions.allow? | type) == "array"
     then .permissions.allow |= map(select(is_marked | not)) else . end)
  | (if (.permissions.deny? | type) == "array"
     then .permissions.deny |= map(select(is_marked | not)) else . end)
  | (if (.hooks? | type) == "object" then
      .hooks |= (
        with_entries(
          .value |= (
            map(if (.hooks? | type) == "array"
                  then .hooks |= map(select((.command? | is_marked) | not))
                  else . end)
            | map(select(((.hooks? // []) | length) > 0))
          )
        )
        | with_entries(select(((.value // []) | length) > 0))
      )
    else . end)
')"; then
  echo "strip-managed-json: jq failed, refusing to stage unfiltered content" >&2
  exit 1
fi

printf '%s\n' "$filtered"
