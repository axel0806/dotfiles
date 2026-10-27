# Claude Code config

`settings.json` is a sanitized copy of `~/.claude/settings.json`. It holds the enabled plugins and marketplaces, so they install on a new machine.

Copy it to `~/.claude/settings.json` on the new device. Secrets live in a local `env` block that is not committed. Add that block by hand on each machine.

Not tracked: `.credentials.json`, session history, projects, backups, and caches.
