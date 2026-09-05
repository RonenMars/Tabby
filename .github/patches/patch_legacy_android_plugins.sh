#!/usr/bin/env bash
set -euo pipefail

for plugin in "${PUB_CACHE:-$HOME/.pub-cache}"/git/uni_links-*/uni_links/android/src/main/java/name/avioli/unilinks/UniLinksPlugin.java; do
  [ -f "$plugin" ] || continue
  perl -0pi -e 's/\n    \/\*\* Plugin registration\. \*\/.*?\n    \}\n\n    \@Override/\n    \@Override/s' "$plugin"
done
