#!/usr/bin/env bash
# Refresh the star counts in profile/README.md from the live GitHub API.
#
# Repos are discovered from the <!--stars:NAME-->COUNT<!--/stars--> placeholders
# already in the file, so adding a project row is all it takes to track it.
# Counts >= 1000 are shown as X.Xk; smaller ones stay raw integers.
#
# Usage: scripts/update-stars.sh [ORG]
set -euo pipefail

ORG="${1:-tigerless-labs}"
README="$(cd "$(dirname "$0")/.." && pwd)/profile/README.md"
[ -f "$README" ] || { echo "$README not found" >&2; exit 1; }

repos=$(grep -o '<!--stars:[A-Za-z0-9._-]\+-->' "$README" | sed 's|<!--stars:||; s|-->||' | sort -u)
[ -n "$repos" ] || { echo "no <!--stars:...--> placeholders in $README" >&2; exit 1; }

for repo in $repos; do
    if ! count=$(gh api "repos/$ORG/$repo" --jq .stargazers_count 2>/dev/null); then
        echo "$repo: skipped (API lookup failed)" >&2
        continue
    fi
    if [ "$count" -ge 1000 ]; then
        display=$(awk -v x="$count" 'BEGIN{printf "%.1fk", x/1000}')
    else
        display="$count"
    fi
    # [^<]* matches both raw (825) and abbreviated (3.5k) current values
    sed -i "s|<!--stars:$repo-->[^<]*<!--/stars-->|<!--stars:$repo-->$display<!--/stars-->|" "$README"
    echo "$repo: $display"
done
