---
name: marketplace-manager
model: haiku
description: Manage and fix Claude Code plugin marketplaces -- audit for issues, register/remove/create plugins, update entries, sync versions, configure distribution, and maintain marketplace.json manifests. Use when working with marketplace catalogs, plugin entries, team distribution settings, or fixing marketplace inconsistencies.
---

# CC Marketplace Manager

## Purpose

Manage Claude Code plugin marketplaces: plugin registration, entry maintenance, version syncing, and distribution configuration. This skill is the authority on marketplace.json structure and plugin catalog operations.

## When to Use

- Auditing and fixing marketplace issues
- Registering a plugin in a marketplace
- Removing a plugin from a marketplace
- Updating plugin entries (description, keywords, category, version)
- Syncing versions between plugin.json and marketplace.json
- Setting up marketplace distribution for teams
- Reviewing or auditing marketplace manifests
- Configuring marketplace metadata (name, owner, pluginRoot)

## Marketplace Manifest

**File location:** `.claude-plugin/marketplace.json`

### Required Fields

```json
{
  "name": "marketplace-identifier",
  "owner": {
    "name": "Maintainer Name"
  },
  "plugins": []
}
```

### Optional Fields

- `description`: Marketplace overview text
- `version`: Release version
- `pluginRoot`: Base path for relative plugin sources

## Plugin Entry Schema

Each entry in the `plugins` array:

**Required:**

- `name`: Plugin identifier (kebab-case, must match plugin.json)
- `source`: Plugin origin specification

**Optional:**

- `description`, `version`, `author`, `homepage`, `repository`, `license`
- `keywords`: Array of search terms
- `category`: Classification (e.g., "framework", "productivity")
- `tags`: Additional discovery tags
- `commands`, `agents`, `hooks`, `mcpServers`: Component path overrides

## Registering a Plugin

### 1. Ensure plugin.json Exists

Before registering, check that the plugin has `.claude-plugin/plugin.json`. If it is missing, create it:

```bash
mkdir -p plugins/<plugin-name>/.claude-plugin
```

```json
{
  "name": "plugin-name",
  "version": "0.1.0",
  "description": "Plugin description",
  "author": {
    "name": "Author Name"
  },
  "keywords": ["keyword1", "keyword2"]
}
```

The `name` field is required. `version`, `description`, `author`, and `keywords` are strongly recommended.

### 2. Add Marketplace Entry

Add an entry to the `plugins` array in `.claude-plugin/marketplace.json`. The `name` must match the plugin's `plugin.json` name exactly:

```json
{
  "name": "plugin-name",
  "source": "./plugins/plugin-name",
  "description": "Plugin description",
  "version": "0.1.0",
  "keywords": ["keyword1", "keyword2"],
  "category": "productivity"
}
```

## Audit & Fix

When asked to audit, fix, or health-check a marketplace, perform the following steps:

### 1. Scan for Unregistered Plugins

List all directories under the plugins root (e.g., `plugins/`). Compare against entries in `.claude-plugin/marketplace.json`. Any plugin directory not listed in the marketplace is unregistered.

**Fix:** For each unregistered plugin, follow the full registration flow (ensure plugin.json, add marketplace entry).

### 2. Detect Name Mismatches

For each registered plugin, read its `plugin.json` and compare the `name` field to:

- The marketplace entry `name`
- The plugin directory name

All three should be consistent. Typos in any location cause install failures.

**Fix:** Correct the mismatched `name` to be consistent across plugin.json, marketplace entry, and directory name. Prefer the directory name as the source of truth.

### 3. Detect Missing plugin.json

For each plugin directory, check that `.claude-plugin/plugin.json` exists.

**Fix:** Create it using the directory name and any available metadata from the marketplace entry.

### 4. Detect Version Drift

For each registered plugin, compare versions between `plugin.json` and the marketplace entry.

**Fix:** Update the stale location to match. Prefer `plugin.json` as the source of truth.

### 5. Detect Stale Entries

For each marketplace entry, verify the source path resolves to an actual plugin directory.

**Fix:** Remove entries whose source no longer exists, or correct the path.

### 6. Report

Summarize all findings and fixes applied.

## Source Specifications

### Relative Path

```json
{ "source": "./plugins/my-plugin" }
```

### GitHub

```json
{ "source": { "source": "github", "repo": "owner/repo" } }
```

### Generic Git URL

```json
{ "source": { "source": "url", "url": "https://git.example.com/plugin.git" } }
```

## Version Syncing

Versions must match in both locations:

1. `plugins/<name>/.claude-plugin/plugin.json`
2. `.claude-plugin/marketplace.json` (matching plugin entry)

Use semantic versioning:

- **Major (x.0.0)**: Breaking changes
- **Minor (0.x.0)**: New features, refactoring
- **Patch (0.0.x)**: Bug fixes, documentation

## Team Distribution

Configure automatic marketplace availability via `.claude/settings.json`:

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

## Local Testing

```bash
# Add marketplace
/plugin marketplace add /path/to/marketplace-root

# Install plugin
/plugin install plugin-name@marketplace-name

# After changes: reinstall
/plugin uninstall plugin-name@marketplace-name
/plugin install plugin-name@marketplace-name
```

## Reference Docs

| Reference                          | Content                                          |
| ---------------------------------- | ------------------------------------------------ |
| `references/plugin-structure.md`   | Directory structure, manifest schema, components |
| `references/marketplace-schema.md` | Marketplace format, plugin entries, distribution |
| `references/workflows.md`          | Marketplace workflows, testing, publishing       |
