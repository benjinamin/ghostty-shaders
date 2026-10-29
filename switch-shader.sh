#!/usr/bin/env bash
# Pick a Ghostty shader from ~/GhosttyShaders and make it the active shader.
# The chosen file is copied to ~/.config/ghostty/shaders/shader.glsl,
# which ~/.config/ghostty/config loads via `custom-shader`.
#
# Usage: switch-shader.sh [-y|--restart] [-n|--no-restart] [filter]
#   filter          optional text; only show shaders whose path contains it
#   -y, --restart   restart Ghostty after the change without asking
#   -n, --no-restart  do not restart Ghostty
#
# Keys: Up/Down or k/j move, Enter selects, q or Esc quits.

set -euo pipefail

SRC_DIR="${GHOSTTY_SHADER_SRC:-$HOME/GhosttyShaders}"
DEST_DIR="$HOME/.config/ghostty/shaders"
DEST="$DEST_DIR/shader.glsl"
OFF="(off - no shader effect)"
RESTART=ask
FILTER=""

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--restart)    RESTART=yes ;;
        -n|--no-restart) RESTART=no ;;
        -h|--help)       sed -n '2,12p' "$0"; exit 0 ;;
        -*)              echo "Unknown option: $1" >&2; exit 2 ;;
        *)               FILTER="$1" ;;
    esac
    shift
done

if [ ! -d "$SRC_DIR" ]; then
    echo "Shader folder not found: $SRC_DIR" >&2
    exit 1
fi

# Collect .glsl files (bash 3.2 compatible, no mapfile).
SHADERS=()
while IFS= read -r f; do
    rel="${f#"$SRC_DIR"/}"
    if [ -z "$FILTER" ] || [[ "$rel" == *"$FILTER"* ]]; then
        SHADERS+=("$rel")
    fi
done < <(find "$SRC_DIR" -type f -name '*.glsl' -not -path '*/.git/*' | sort)

if [ "${#SHADERS[@]}" -eq 0 ]; then
    echo "No .glsl files found in $SRC_DIR${FILTER:+ matching '$FILTER'}" >&2
    exit 1
fi

ITEMS=("${SHADERS[@]}" "$OFF")
choice=""

# --- Arrow-key menu ----------------------------------------------------------
SCREEN_ACTIVE=0
restore_screen() {
    if [ "$SCREEN_ACTIVE" -eq 1 ]; then
        tput cnorm 2>/dev/null || true   # show cursor
        tput rmcup 2>/dev/null || true   # leave alternate screen
        SCREEN_ACTIVE=0
    fi
}
trap restore_screen EXIT
trap 'restore_screen; echo "Cancelled."; exit 130' INT TERM

arrow_menu() {
    local n=${#ITEMS[@]} sel=0 top=0 rows i key rest

    # Start on the currently active shader, if it is in the list.
    if [ -f "$DEST" ]; then
        for ((i = 0; i < n - 1; i++)); do
            if cmp -s "$SRC_DIR/${ITEMS[i]}" "$DEST"; then sel=$i; break; fi
        done
    fi

    tput smcup; tput civis; SCREEN_ACTIVE=1

    while true; do
        rows=$(( $(tput lines) - 4 ))
        [ "$rows" -lt 3 ] && rows=3
        [ "$sel" -lt "$top" ] && top=$sel
        [ "$sel" -ge $((top + rows)) ] && top=$((sel - rows + 1))

        tput cup 0 0
        printf 'Shaders in %s\e[K\n' "$SRC_DIR"
        printf '\e[2m Up/Down move · Enter select · q quit\e[0m\e[K\n'
        for ((i = top; i < n && i < top + rows; i++)); do
            if [ "$i" -eq "$sel" ]; then
                printf '\e[7m > %s \e[0m\e[K\n' "${ITEMS[i]}"
            else
                printf '   %s\e[K\n' "${ITEMS[i]}"
            fi
        done
        if [ "$n" -gt "$rows" ]; then
            printf '\e[2m   [%d/%d]\e[0m\e[K' $((sel + 1)) "$n"
        fi
        tput ed   # clear the rest of the screen

        IFS= read -rsn1 key || return 1
        case "$key" in
            $'\e')
                rest=""
                read -rsn2 -t 1 rest || true
                case "$rest" in
                    '[A'|'OA') key=up ;;
                    '[B'|'OB') key=down ;;
                    '')        return 1 ;;   # plain Esc
                    *)         key="" ; continue ;;
                esac ;;
            k) key=up ;;
            j) key=down ;;
            q|Q) return 1 ;;
            '') choice="${ITEMS[sel]}"; return 0 ;;   # Enter
            *) continue ;;
        esac

        if [ "$key" = up ]; then
            if [ "$sel" -gt 0 ]; then sel=$((sel - 1)); else sel=$((n - 1)); fi
        elif [ "$key" = down ]; then
            if [ "$sel" -lt $((n - 1)) ]; then sel=$((sel + 1)); else sel=0; fi
        fi
    done
}

# --- Numbered fallback (when input is not a terminal) ------------------------
number_menu() {
    echo "Shaders in $SRC_DIR:"
    PS3=$'\nChoose a shader number (Ctrl+C to cancel): '
    select choice in "${ITEMS[@]}"; do
        [ -n "${choice:-}" ] && return 0
        echo "Invalid choice. Try again."
    done
    return 1
}

if [ -t 0 ] && [ -t 1 ]; then
    if ! arrow_menu; then
        restore_screen
        echo "Cancelled. Shader not changed."
        exit 0
    fi
    restore_screen
else
    number_menu || { echo "No choice. Shader not changed."; exit 1; }
fi

# --- Apply -------------------------------------------------------------------
mkdir -p "$DEST_DIR"

if [ "$choice" = "$OFF" ]; then
    cat > "$DEST" <<'EOF'
// Pass-through shader: shows the terminal unchanged.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
}
EOF
    echo "Shader turned off."
else
    cp "$SRC_DIR/$choice" "$DEST"
    echo "Active shader: $choice"
fi

echo "Written to: $DEST"

# --- Restart Ghostty ---------------------------------------------------------
# Ghostty loads custom shaders only at start, so it must quit and start again.
# This script usually runs inside Ghostty, so a detached helper does the
# restart: it survives Ghostty quitting, waits for it to exit, then reopens it.
restart_ghostty() {
    nohup perl -MPOSIX -e 'POSIX::setsid(); exec @ARGV' /bin/bash -c '
        sleep 1
        osascript -e "tell application \"Ghostty\" to quit" >/dev/null 2>&1 || exit 0
        # Wait up to 60 s (time to answer a "close running processes?" dialog).
        for _ in $(seq 1 120); do
            pgrep -axq ghostty || break
            sleep 0.5
        done
        pgrep -axq ghostty && exit 0   # quit was cancelled: do not reopen
        sleep 0.5
        open -a Ghostty
    ' >/dev/null 2>&1 &
}

if ! pgrep -axq ghostty; then
    echo "Ghostty is not running. The new shader loads when you start it."
    exit 0
fi

if [ "$RESTART" = ask ]; then
    if [ -t 0 ]; then
        printf 'Restart Ghostty now to load the shader? All Ghostty windows close. [Y/n] '
        read -r answer || answer=n
        case "$answer" in [nN]*) RESTART=no ;; *) RESTART=yes ;; esac
    else
        RESTART=no
    fi
fi

if [ "$RESTART" = yes ]; then
    restart_ghostty
    echo "Restarting Ghostty..."
else
    echo "Quit Ghostty fully (Cmd+Q) and start it again to load the shader."
fi
