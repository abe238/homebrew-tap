# homebrew-tap

Homebrew formulae for tools by abe238.

## Onionskin

[Onionskin](https://onionskin.abediaz.ai) lets you review and edit Word, Excel, PowerPoint, HTML and Markdown files with Claude Code or Codex, in a browser editor on your Mac.

```sh
brew install abe238/tap/onionskin
onionskin setup
```

`onionskin setup` installs the agent skill for Claude Code and Codex.

To update:

```sh
brew upgrade onionskin
onionskin setup --force
```

To remove:

```sh
onionskin setup --uninstall
brew uninstall onionskin
```

Onionskin needs macOS and Claude Code or Codex. Source and issues: https://github.com/abe238/onionskin

License: MIT.
