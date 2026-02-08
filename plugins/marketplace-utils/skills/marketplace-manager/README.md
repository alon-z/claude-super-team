# CC Marketplace Manager

A skill for managing and fixing Claude Code plugin marketplaces -- auditing for issues, registering plugins, maintaining catalog entries, syncing versions, and configuring distribution.

## Purpose

Marketplace Manager is the authority on marketplace.json structure and plugin catalog operations. It handles everything related to the marketplace itself: adding and removing plugin entries, keeping versions in sync, auditing manifests, and setting up team distribution.

For creating new plugins, use the skill-creator skill instead.

## When to Use

Use this skill when you need to:

- **Audit & fix** - "Fix the marketplace", "Audit marketplace for issues", "Health-check the marketplace"
- **Register plugins** - "Add this plugin to the marketplace"
- **Remove plugins** - "Remove plugin from marketplace"
- **Update entries** - "Update the description for this plugin in the marketplace"
- **Sync versions** - "Sync plugin version to marketplace", "Bump version in both manifests"
- **Manage marketplace metadata** - "Update marketplace owner", "Change marketplace name"
- **Configure distribution** - "Set up marketplace for the team", "Add marketplace to settings"

**Trigger phrases:**
- "Fix the marketplace"
- "Audit marketplace"
- "Register plugin in marketplace"
- "Update marketplace.json"
- "Sync plugin versions"
- "Set up team distribution"
- "Add/remove plugin entry"

## How It Works

### Audit & Fix

1. Scan plugins root for directories not listed in marketplace.json
2. Check each plugin has `.claude-plugin/plugin.json` (create if missing)
3. Compare names across directory, plugin.json, and marketplace entry (fix mismatches)
4. Compare versions between plugin.json and marketplace entry (fix drift)
5. Remove stale marketplace entries pointing to nonexistent directories
6. Report all findings and fixes

### Plugin Registration

1. Ensure the plugin has a `.claude-plugin/plugin.json` manifest (create if missing)
2. Build the marketplace entry with required and optional fields
3. Add the entry to the `plugins` array in `.claude-plugin/marketplace.json`
4. Verify source path or URL is correct

### Version Syncing

1. Read current version from `plugins/<name>/.claude-plugin/plugin.json`
2. Update the matching entry in `.claude-plugin/marketplace.json`
3. Confirm both locations are in sync

### Team Distribution

1. Identify the marketplace source (GitHub repo or local path)
2. Configure `extraKnownMarketplaces` in `.claude/settings.json`
3. Team members automatically get access to the marketplace

## Key Features

### Marketplace Operations

| Operation | Description |
|-----------|-------------|
| Audit & fix | Scan for issues and fix them (unregistered plugins, name mismatches, missing plugin.json, version drift, stale entries) |
| Register plugin | Add a new plugin entry to marketplace.json |
| Remove plugin | Remove a plugin entry from marketplace.json |
| Update entry | Modify plugin metadata (description, keywords, category) |
| Sync versions | Keep plugin.json and marketplace.json versions aligned |

### Source Types

| Type | Format |
|------|--------|
| Relative path | `"./plugins/my-plugin"` |
| GitHub | `{ "source": "github", "repo": "owner/repo" }` |
| Git URL | `{ "source": "url", "url": "https://..." }` |

### Reference Documentation

| Document | Content |
|----------|---------|
| `plugin-structure.md` | Directory hierarchy, manifest schema, component types |
| `marketplace-schema.md` | Marketplace format, plugin entries, source specifications |
| `workflows.md` | Marketplace workflows, testing, publishing |

## Usage Examples

### Register a Plugin

Add entry to `.claude-plugin/marketplace.json`:

```json
{
  "name": "my-plugin",
  "source": "./plugins/my-plugin",
  "description": "A useful plugin",
  "version": "1.0.0",
  "keywords": ["utility"],
  "category": "productivity"
}
```

### Sync Version After a Bump

After updating `plugins/my-plugin/.claude-plugin/plugin.json` to version `1.1.0`, update the matching entry in `.claude-plugin/marketplace.json` to `"version": "1.1.0"`.

### Set Up Team Distribution

Add to `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": [
    {
      "source": {
        "source": "github",
        "repo": "company/marketplace"
      }
    }
  ]
}
```

### Local Testing

```bash
# Add marketplace
/plugin marketplace add /path/to/marketplace-root

# Install plugin
/plugin install my-plugin@marketplace-name

# After changes, reinstall
/plugin uninstall my-plugin@marketplace-name
/plugin install my-plugin@marketplace-name
```

## Marketplace Manifest Structure

```json
{
  "name": "marketplace-identifier",
  "description": "Marketplace overview",
  "version": "1.0.0",
  "owner": {
    "name": "Maintainer Name",
  },
  "pluginRoot": "./plugins",
  "plugins": [
    {
      "name": "plugin-name",
      "source": "./plugins/plugin-name",
      "description": "Plugin description",
      "version": "1.0.0",
      "keywords": ["keyword1"],
      "category": "productivity"
    }
  ]
}
```

## Best Practices

### Naming

- Marketplace names: `kebab-case` (e.g., `company-tools`)
- Plugin names in entries must match the plugin's own `plugin.json` name exactly

### Versioning

- Always use semantic versioning
- Keep versions in sync between `plugin.json` and `marketplace.json`
- Bump in both locations whenever a plugin version changes

### Manifest Hygiene

- Remove entries for deleted plugins
- Keep descriptions and keywords current
- Use consistent categories across the marketplace

### Distribution

- Use GitHub source for team/public marketplaces
- Use relative paths for local development only
- Configure `extraKnownMarketplaces` in project `.claude/settings.json` for team-wide access

## Troubleshooting

### Plugin not found after registration

- Verify the `source` path points to a valid plugin directory
- Ensure the plugin has `.claude-plugin/plugin.json`
- Check that the `name` field matches

### Version mismatch

- Compare versions in `plugin.json` and the marketplace entry
- Update both to match

### Changes not taking effect

- Reinstall the plugin: uninstall then install again
- Restart Claude Code (plugin files are cached)

### Marketplace not visible to team

- Verify `extraKnownMarketplaces` is configured in `.claude/settings.json`
- Check that the GitHub repo is accessible to team members
