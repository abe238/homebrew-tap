# homebrew-tap

Homebrew formulae for tools by abe238.

| Tool | Install | What it does |
| --- | --- | --- |
| [Onionskin](https://onionskin.abediaz.ai) | `brew install abe238/tap/onionskin` | Review and edit Word, Excel, PowerPoint, HTML and Markdown files with Claude Code or Codex |
| [hotin](https://hotin.ai) | `brew install abe238/tap/hotin` | See what is hot in AI, from your terminal |
| [RealStop](https://decisiontune.com/realstop/) | `brew install abe238/tap/realstop` | A Claude Code Stop hook that catches coding agents handing back unfinished work |
| [nhc-pp-cli](https://github.com/abe238/nhc-pp-cli) | `brew install abe238/tap/nhc-pp-cli` | National Hurricane Center storms, advisories and outlooks, for agents (unofficial) |
| [shelters-pp-cli](https://github.com/abe238/shelters-pp-cli) | `brew install abe238/tap/shelters-pp-cli` | Open FEMA and Red Cross emergency shelters, for agents (unofficial) |

Update any of them with `brew upgrade <name>`. Remove one with `brew uninstall <name>`.

## After installing

- **Onionskin:** run `onionskin setup` to install the agent skill for Claude Code and Codex. After an upgrade, run `onionskin setup --force`. Before uninstalling, run `onionskin setup --uninstall`. Needs macOS.
- **RealStop:** run `realstop setup` to add the hook to Claude Code. Run it again after an upgrade.
- **hotin, nhc-pp-cli, shelters-pp-cli:** nothing else to do.

Each tool's license is in its own repository.

Formulae are kept current by a scheduled check (`.github/workflows/bump.yml`): it finds a tool's new release, installs and tests the formula, and only then publishes it.
