#!/usr/bin/env bash
# Add a shell alias for switch-shader.sh, pointing at this repo wherever it is.
#
# Usage: ./install-alias.sh [alias-name]     (default name: gshader)
# Run it again after moving the repo; it updates the existing alias.

set -euo pipefail

NAME="${1:-gshader}"
case "$NAME" in
    *[!A-Za-z0-9_-]*|'') echo "Invalid alias name: $NAME" >&2; exit 2 ;;
esac

REPO_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$REPO_DIR/switch-shader.sh"
chmod +x "$TARGET"

# Pick the rc file for the user's login shell.
case "$(basename "${SHELL:-}")" in
    zsh)  RC="$HOME/.zshrc" ;;
    bash) if [ "$(uname)" = Darwin ]; then RC="$HOME/.bash_profile"; else RC="$HOME/.bashrc"; fi ;;
    *)    echo "Unsupported shell '${SHELL:-unknown}'. Add this line yourself:" >&2
          echo "  alias $NAME=\"$TARGET\"" >&2
          exit 1 ;;
esac
touch "$RC"

LINE="alias $NAME=\"$TARGET\""
MARK="# ghostty-shaders switcher"

if grep -Fqx "$LINE" "$RC"; then
    echo "Alias '$NAME' is already set in $RC."
    exit 0
fi

if grep -Eq "^alias $NAME=" "$RC"; then
    # Replace an existing alias with this name (e.g. after moving the repo).
    tmp="$RC.tmp.$$"
    awk -v name="$NAME" -v line="$LINE" \
        'index($0, "alias " name "=") == 1 { print line; next } { print }' "$RC" > "$tmp"
    cat "$tmp" > "$RC" && rm -f "$tmp"
    echo "Updated alias '$NAME' in $RC."
else
    printf '\n%s\n%s\n' "$MARK" "$LINE" >> "$RC"
    echo "Added alias '$NAME' to $RC."
fi

echo "Open a new terminal, or run: source $RC"
echo "Then run: $NAME"
