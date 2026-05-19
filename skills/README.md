# skills

Personal skill library for Claude Code and Codex.

Both Claude Code and Codex consume the same Anthropic Skills format — a directory containing a `SKILL.md` with `name` / `description` frontmatter, plus optional `scripts/`, `references/`, etc. This folder is the source of truth; `install.sh` places each skill into the right runtime directory.

## Layout

```
skills/
├── install.sh        # installer (symlink or copy, per-platform or both)
├── _template/        # starter SKILL.md for new skills (not installed)
├── claude/           # skills installed only to ~/.claude/skills/
├── codex/            # skills installed only to ~/.codex/skills/
└── shared/           # skills installed to both
```

Drop a third-party skill into `claude/`, `codex/`, or `shared/` (whichever applies) and run the installer. Self-written skills follow the same rule.

Where to put what:

| Platform compatibility | Folder |
| --- | --- |
| Uses Claude-only features (e.g. the built-in `Skill` tool, Claude subagents) | `claude/` |
| Uses Codex-only features or paths | `codex/` |
| Pure prompt / docs / scripts that work either way | `shared/` |

## Install

```bash
# default: symlink every skill to both ~/.claude/skills and ~/.codex/skills
./install.sh

# only Claude (claude/* + shared/*)
./install.sh --target claude

# copy instead of symlink (snapshot — repo edits won't propagate)
./install.sh --mode copy

# install one skill by directory name
./install.sh --skill my-skill

# preview without touching disk
./install.sh --dry-run

# replace anything already at the destination
./install.sh --force
```

Symlink mode is the default and matches the existing `~/.agents/skills` pattern: editing files in this repo is reflected instantly, and `git pull` updates everything.

Copy mode is for environments where symlinks aren't ideal (e.g. shipping to a remote box) — re-run `install.sh --mode copy --force` after changes.

## Uninstall

```bash
./install.sh --uninstall                 # remove every installed symlink
./install.sh --uninstall --skill foo     # just one
./install.sh --uninstall --force         # also remove directory copies
```

Symlinks are removed unconditionally. Directory copies require `--force` to avoid accidentally deleting files that were edited in-place.

## Adding a new skill

```bash
cp -R _template claude/my-new-skill   # or codex/, or shared/
$EDITOR claude/my-new-skill/SKILL.md  # fill in name + description + body
./install.sh --skill my-new-skill
```

The `name:` in frontmatter should match the directory name. Keep the `description:` specific — it's what the runtime uses to decide when to load the skill.

## Notes

- Directories whose names start with `_` (e.g. `_template`) are ignored by the installer.
- Override destinations with `CLAUDE_SKILLS_DIR` / `CODEX_SKILLS_DIR` environment variables if your runtime config lives somewhere non-standard.
- The installer is idempotent: it skips entries that already exist unless `--force` is passed.
