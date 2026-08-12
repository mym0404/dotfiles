#!/bin/zsh
set -euo pipefail

export PATH="$HOME/.local/share/mise/shims:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if ! codex plugin marketplace list --json | /usr/bin/jq -e '.marketplaces[]? | select(.name == "ponytail")' >/dev/null; then
  codex plugin marketplace add https://github.com/DietrichGebert/ponytail.git
fi

installed_plugins="$(codex plugin list --json)"
for plugin in google-calendar@openai-curated slack@openai-curated ponytail@ponytail; do
  if ! /usr/bin/jq -e --arg plugin "$plugin" '.installed[]? | select(.pluginId == $plugin)' >/dev/null <<<"$installed_plugins"; then
    codex plugin add "$plugin"
  fi
done
