# claude/

Skills installed only to `~/.claude/skills/`. Use this folder for skills that depend on Claude Code features — the built-in `Skill` tool, subagents, hooks, slash-command integration, or `.claude/`-specific paths.

If a skill is platform-agnostic, put it in `../shared/` instead.

Each subdirectory must be a self-contained skill rooted at a `SKILL.md` file. The directory name becomes the installed skill name and should match the `name:` field in frontmatter.
