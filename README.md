# PersonalConfig

个人配置仓库，当前安装脚本主要面向 Linux。

```bash
# 预览，然后单独应用 Helix 配置（不安装软件）
sh scripts/config.sh apply helix --dry-run
sh scripts/config.sh apply helix

# 单独安装 Helix（不改配置）
sh scripts/config.sh install helix --dry-run
sh scripts/config.sh install helix
```

| 组件 | 应用配置 | 安装方式 / 前置条件 |
| --- | --- | --- |
| `helix` | `config.toml`、`languages.toml` | 官方 Linux x86_64/aarch64 25.07.1 压缩包，需要 curl、tar、xz |
| `starship` | `starship.toml` | `cargo install --locked starship`，需要 Rust 工具链和编译环境 |
| `yazi` | 四个配置文件 | `cargo install --locked yazi-build`，需要 Rust 工具链和编译环境 |
| `zellij` | `config.kdl` | `cargo install --locked zellij`，需要 Rust 工具链和编译环境 |
| `basedpyright` | 无 | `uv tool install basedpyright`，需要 uv |
| `ruff` | 无 | `uv tool install ruff`，需要 uv |
| `rust-tools` | 无 | rustup 为当前工具链添加 rust-analyzer、rustfmt、clippy |
| `clangd` | 无 | Debian/Ubuntu apt 安装 clangd、clang-format，需要 root 或 sudo |

例如，逐项安装 Helix 的语言支持：

```bash
sh scripts/config.sh install basedpyright
sh scripts/config.sh install ruff
sh scripts/config.sh install rust-tools
sh scripts/config.sh install clangd
hx --health python
hx --health rust
hx --health cpp
```

脚本不会自动安装 uv、Rust 或编译依赖。Cargo 软件的系统依赖以安装输出为准。Yazi 的图片、视频、PDF 等预览依赖需按需自行安装。已有包由对应工具决定跳过或报错，不自动强制升级。

配置通过逐文件符号链接应用到 `${XDG_CONFIG_HOME:-~/.config}`，保留该目录中的其他文件。已有同名文件、目录或链接会移动到旁边的 `*.bak-时间戳`，重复应用正确链接不再备份。仓库移动后需重新应用。恢复时移除对应链接，将备份改回原名即可。`--dry-run` 不写文件、不下载、不执行安装命令。

Helix 安装到 `~/.local/opt/helix-25.07.1-<架构>-linux`，`~/.local/bin/hx` 链接到其中的程序，保留同目录 runtime。请将 `~/.local/bin`、`~/.cargo/bin` 和 uv 的工具目录加入 PATH。自定义 `STARSHIP_CONFIG` 会优先于默认配置路径；Starship 的 shell 初始化需自行添加。脚本不修改 shell 启动文件。

Helix 的两个主配置文件同步自本机配置：Frappe 主题、多 buffer 标签、inlay hints，以及 Python / Rust / C / C++ 语言支持。仓库历史主题保留在 `helix/themes/` 供参考，不自动应用；当前使用 Helix 自带的 Frappe 主题。Python 项目模板 `python/pyproject.toml` 供手动复制，不作为全局配置安装。

Skill 使用独立入口，明确选择平台及名称：

```bash
bash skills/install.sh --target codex --skill documentation --dry-run
bash skills/install.sh --target codex --skill documentation
```

更多选项见 [skills/README.md](skills/README.md)。软件脚本不会调用 skill 安装器。

安装方式参考：[Helix 官方安装说明](https://docs.helix-editor.com/install.html)、[Yazi 官方安装说明](https://yazi-rs.github.io/docs/installation/)。
