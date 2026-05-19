#!/usr/bin/env bash
# Install personal skills into ~/.claude/skills and/or ~/.codex/skills.
#
# Layout (relative to this script):
#   claude/<name>/SKILL.md   -> installed only to ~/.claude/skills/<name>
#   codex/<name>/SKILL.md    -> installed only to ~/.codex/skills/<name>
#   shared/<name>/SKILL.md   -> installed to both
#
# See ./README.md for details.

set -euo pipefail

MODE="symlink"
TARGET="all"
ACTION="install"
SKILL=""
FORCE=0
DRY=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --mode <symlink|copy>          how to place skills (default: symlink)
  --target <claude|codex|all>    which platform to install to (default: all)
  --skill <name>                 only act on the named skill (default: all)
  --uninstall                    remove what install would have placed
  --force                        overwrite/remove existing entries at destination
  --dry-run                      print actions without performing them
  -h, --help                     show this help

Environment overrides:
  CLAUDE_SKILLS_DIR  destination for Claude Code skills (default: ~/.claude/skills)
  CODEX_SKILLS_DIR   destination for Codex skills       (default: ~/.codex/skills)

Examples:
  ./install.sh                           # symlink every skill to both platforms
  ./install.sh --target claude           # only Claude (claude/* + shared/*)
  ./install.sh --mode copy --force       # copy + replace any existing entries
  ./install.sh --skill my-skill          # install just one skill
  ./install.sh --uninstall --skill foo   # remove just one skill
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)      MODE="${2:-}"; shift 2 ;;
    --target)    TARGET="${2:-}"; shift 2 ;;
    --skill)     SKILL="${2:-}"; shift 2 ;;
    --uninstall) ACTION="uninstall"; shift ;;
    --force)     FORCE=1; shift ;;
    --dry-run)   DRY=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "error: unknown option '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE"   in symlink|copy)     ;; *) echo "error: --mode must be symlink|copy"     >&2; exit 2 ;; esac
case "$TARGET" in claude|codex|all) ;; *) echo "error: --target must be claude|codex|all" >&2; exit 2 ;; esac

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CLAUDE_DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
CODEX_DEST="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"

run() {
  if [[ $DRY -eq 1 ]]; then
    printf 'DRY: %s\n' "$*"
  else
    "$@"
  fi
}

# Resolve absolute paths even when ln/cp need them.
abs() { (cd "$1" && pwd); }

install_one() {
  local src="$1" dest_root="$2"
  local name dest
  name="$(basename "$src")"
  dest="$dest_root/$name"

  run mkdir -p "$dest_root"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ $FORCE -eq 1 ]]; then
      run rm -rf "$dest"
    else
      printf 'skip:  %-40s (exists; use --force to replace)\n' "$dest" >&2
      return 0
    fi
  fi

  if [[ "$MODE" == "symlink" ]]; then
    run ln -s "$(abs "$src")" "$dest"
    printf 'link:  %s -> %s\n' "$dest" "$src"
  else
    run cp -R "$src" "$dest"
    printf 'copy:  %s\n' "$dest"
  fi
}

uninstall_one() {
  local src="$1" dest_root="$2"
  local name dest
  name="$(basename "$src")"
  dest="$dest_root/$name"

  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    printf 'skip:  %-40s (not present)\n' "$dest" >&2
    return 0
  fi

  if [[ -L "$dest" ]]; then
    run rm "$dest"
    printf 'unlink: %s\n' "$dest"
    return 0
  fi

  if [[ $FORCE -eq 1 ]]; then
    run rm -rf "$dest"
    printf 'remove: %s\n' "$dest"
  else
    printf 'skip:  %-40s (directory copy; use --force to remove)\n' "$dest" >&2
  fi
}

# Iterate skill directories under skills/<platform_dir>/. Skips empty dirs and
# honors --skill filter.
each_skill() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  local s name
  for s in "$dir"/*/; do
    [[ -d "$s" ]] || continue
    s="${s%/}"
    name="$(basename "$s")"
    [[ "$name" == _* ]] && continue   # ignore _template, _scratch, etc.
    if [[ -n "$SKILL" && "$SKILL" != "$name" ]]; then
      continue
    fi
    printf '%s\n' "$s"
  done
}

apply() {
  local fn="$1" platform_dir="$2" dest_root="$3"
  local s
  while IFS= read -r s; do
    [[ -z "$s" ]] && continue
    "$fn" "$s" "$dest_root"
  done < <(each_skill "$SCRIPT_DIR/$platform_dir")

  while IFS= read -r s; do
    [[ -z "$s" ]] && continue
    "$fn" "$s" "$dest_root"
  done < <(each_skill "$SCRIPT_DIR/shared")
}

fn="install_one"
[[ "$ACTION" == "uninstall" ]] && fn="uninstall_one"

case "$TARGET" in
  claude) apply "$fn" claude "$CLAUDE_DEST" ;;
  codex)  apply "$fn" codex  "$CODEX_DEST" ;;
  all)
    apply "$fn" claude "$CLAUDE_DEST"
    apply "$fn" codex  "$CODEX_DEST"
    ;;
esac
