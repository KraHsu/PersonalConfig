# shared/

Skills installed to **both** `~/.claude/skills/` and `~/.codex/skills/`. Use this folder for skills whose `SKILL.md` is pure prompt + docs + scripts, with no dependence on platform-specific tools or paths.

Symlink mode means one source dir is linked from both runtimes — edits propagate to both automatically.

Each subdirectory must be a self-contained skill rooted at a `SKILL.md` file. The directory name becomes the installed skill name and should match the `name:` field in frontmatter.
