#!/bin/sh
# Apply one configuration or install one tool at a time.
set -eu

usage() {
    cat <<'HELP'
Usage: sh scripts/config.sh <apply|install> <component> [--dry-run]

Configuration: helix starship yazi zellij
Installation:  helix starship yazi zellij basedpyright ruff rust-tools clangd

Each invocation handles one component. Skill installation: skills/install.sh
HELP
}
fail() { printf 'error: %s\n' "$*" >&2; exit 1; }
case ${1:-} in -h|--help) usage; exit 0 ;; esac
[ "$#" -ge 2 ] && [ "$#" -le 3 ] || { usage >&2; exit 2; }
action=$1
component=$2
dry=0
if [ "$#" -eq 3 ]; then
    [ "$3" = --dry-run ] || fail "unknown option: $3"
    dry=1
fi
case $action in apply|install) ;; *) fail "unknown action: $action" ;; esac
case $component in
    helix|starship|yazi|zellij|basedpyright|ruff|rust-tools|clangd) ;;
    *) fail "unknown component: $component" ;;
esac
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)

run() {
    printf '+'
    for arg do printf ' [%s]' "$arg"; done
    printf '\n'
    if [ "$dry" -eq 0 ]; then "$@"; fi
}
place() {
    source_path=$1
    dest=$2
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$source_path" ]; then
        printf 'unchanged: %s\n' "$dest"
        return
    fi
    printf 'link: %s -> %s\n' "$dest" "$source_path"
    [ "$dry" -eq 0 ] || return 0
    mkdir -p -- "$(dirname -- "$dest")"
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        backup="$dest.bak-$(date +%Y%m%d-%H%M%S)-$$"
        suffix=0
        while [ -e "$backup" ] || [ -L "$backup" ]; do
            suffix=$((suffix + 1))
            backup="$dest.bak-$(date +%Y%m%d-%H%M%S)-$$-$suffix"
        done
        mv -- "$dest" "$backup"
        printf 'backup: %s\n' "$backup"
    fi
    ln -s -- "$source_path" "$dest"
}

if [ "$action" = apply ]; then
    config_home=${XDG_CONFIG_HOME:-$HOME/.config}
    case $config_home in /*) ;; *) fail 'XDG_CONFIG_HOME must be absolute' ;; esac
    case $component in
        helix) set -- config.toml languages.toml ;;
        starship) set -- starship.toml ;;
        yazi) set -- yazi.toml keymap.toml theme.toml init.lua ;;
        zellij) set -- config.kdl ;;
        *) fail "$component has no repository configuration" ;;
    esac
    for name do
        if [ "$component" = starship ]; then
            target="$config_home/$name"
        else
            target="$config_home/$component/$name"
        fi
        place "$repo_root/$component/$name" "$target"
    done
    exit 0
fi

# Installing software does not apply configuration or edit shell startup files.
case $component in
    basedpyright|ruff) run uv tool install "$component" ;;
    rust-tools) run rustup component add rust-analyzer rustfmt clippy ;;
    clangd)
        [ "$(uname -s)" = Linux ] && command -v apt-get >/dev/null 2>&1 ||
            fail 'clangd installation requires Debian/Ubuntu apt-get'
        if [ "$(id -u)" -eq 0 ]; then set --; else set -- sudo; fi
        run "$@" apt-get update
        run "$@" apt-get install -y clangd clang-format
        ;;
    starship|zellij) run cargo install --locked "$component" ;;
    yazi) run cargo install --locked yazi-build ;;
    helix)
        [ "$(uname -s)" = Linux ] || fail 'Helix installation requires Linux'
        arch=$(uname -m)
        case $arch in x86_64|aarch64) ;; *) fail "unsupported architecture: $arch" ;; esac
        name="helix-25.07.1-$arch-linux"
        base="$HOME/.local/opt"
        binary="$base/$name/hx"
        if [ ! -f "$binary" ] || [ ! -d "$base/$name/runtime" ]; then
            url="https://github.com/helix-editor/helix/releases/download/25.07.1/$name.tar.xz"
            if [ "$dry" -eq 1 ]; then
                printf 'download/extract: %s -> %s\n' "$url" "$base"
            else
                temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/personalconfig.XXXXXXXX")
                trap 'rm -rf -- "$temp_dir"' 0
                trap 'exit 130' INT
                trap 'exit 143' TERM
                run curl --fail --location --proto '=https' --output "$temp_dir/helix.tar.xz" "$url"
                mkdir -p -- "$base"
                run tar -xJf "$temp_dir/helix.tar.xz" -C "$base"
                [ -f "$binary" ] && [ -d "$base/$name/runtime" ] ||
                    fail 'Helix archive is missing hx or runtime'
            fi
        fi
        place "$binary" "$HOME/.local/bin/hx"
        ;;
esac
