# Marketplace Workflows

## Registering a Plugin

### 1. Ensure plugin.json Exists

Check whether the plugin has `.claude-plugin/plugin.json`. If it is missing, create the directory and manifest:

```bash
mkdir -p plugins/<plugin-name>/.claude-plugin
```

Create `plugins/<plugin-name>/.claude-plugin/plugin.json`:

```json
{
  "name": "plugin-name",
  "version": "0.1.0",
  "description": "Plugin description",
  "author": {
    "name": "Author Name",
  },
  "keywords": ["keyword1", "keyword2"]
}
```

Required field: `name` (kebab-case, unique across the marketplace).
Strongly recommended: `version`, `description`, `author`, `keywords`.

If plugin.json already exists, read it and use its values for the marketplace entry.

### 2. Add Entry to Marketplace

Update `.claude-plugin/marketplace.json` by adding an entry to the `plugins` array. The `name` must match the plugin's `plugin.json` name exactly:

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

### 3. Verify Registration

- Confirm the marketplace entry is valid JSON
- Confirm the `name` matches plugin.json
- Confirm the source path resolves to the plugin directory
- Confirm versions match between both manifests

## Removing a Plugin

1. Remove the plugin's entry from the `plugins` array in `.claude-plugin/marketplace.json`
2. Optionally remove the plugin directory itself if it is no longer needed

## Version Syncing

When a plugin version changes, update **both** locations:

1. `plugins/<plugin-name>/.claude-plugin/plugin.json`
2. `.claude-plugin/marketplace.json` (matching plugin entry)

**Semantic versioning:**

- **Major (x.0.0)**: Breaking changes
- **Minor (0.x.0)**: New features, refactoring
- **Patch (0.0.x)**: Bug fixes, documentation only

## Local Testing Workflow

### Initial Setup

```bash
# Add marketplace
/plugin marketplace add /path/to/marketplace-root

# Install plugin
/plugin install plugin-name@marketplace-name
```

### Iterative Testing

After making changes to a plugin or marketplace entry:

```bash
# Uninstall
/plugin uninstall plugin-name@marketplace-name

# Reinstall
/plugin install plugin-name@marketplace-name

# Restart Claude Code to load changes
```

**Note:** Claude Code caches plugin files, so restart may be required for changes to take effect.

## Publishing Workflow

### 1. Commit Changes

Use conventional commits:

```bash
git commit -m "feat: register new plugin"
git commit -m "fix: correct marketplace entry"
git commit -m "docs: update marketplace metadata"
```

### 2. Push to Repository

```bash
git push origin main
```

### 3. Distribution

**GitHub-hosted marketplace:**

Users add via:

```bash
/plugin marketplace add owner/repo
/plugin install plugin-name@marketplace-name
```

**Local marketplace:**

Users add via absolute path:

```bash
/plugin marketplace add /path/to/marketplace
```

## Team Distribution Setup

### Configure for Automatic Access

Add to project `.claude/settings.json`:

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

This makes the marketplace automatically available to all team members who clone the project.

## Audit & Fix Workflow

When asked to audit, fix, or health-check a marketplace, run through every check below. Fix issues as you find them.

### Step 1: Locate the Marketplace

Read `.claude-plugin/marketplace.json` at the repository root. Identify the plugins root directory (explicit `pluginRoot` field, or default `./plugins`).

### Step 2: Scan for Unregistered Plugins

List all subdirectories under the plugins root. Compare against the `name` / `source` entries in marketplace.json.

**Issue:** A plugin directory exists but has no marketplace entry.
**Fix:** Follow the full registration flow -- ensure plugin.json exists (create if missing), then add the marketplace entry.

### Step 3: Detect Missing plugin.json

For each plugin directory (registered or not), check that `.claude-plugin/plugin.json` exists.

**Issue:** Plugin directory has no `.claude-plugin/plugin.json`.
**Fix:** Create the directory and manifest. Use the directory name as the `name`, and pull description/version/keywords from the marketplace entry if one exists.

### Step 4: Detect Name Mismatches

For each registered plugin, compare three values:
1. The plugin directory name
2. The `name` field in `.claude-plugin/plugin.json`
3. The `name` field in the marketplace entry

All three must be identical. Typos in any location cause install failures.

**Issue:** Names are inconsistent (e.g., typo in plugin.json).
**Fix:** Correct the mismatched value. Use the directory name as the source of truth.

### Step 5: Detect Version Drift

For each registered plugin that has both a plugin.json `version` and a marketplace entry `version`, compare them.

**Issue:** Versions differ between plugin.json and marketplace entry.
**Fix:** Update the stale location to match. Use plugin.json as the source of truth.

### Step 6: Detect Stale Entries

For each marketplace entry, verify the source path resolves to an actual plugin directory.

**Issue:** Marketplace entry points to a directory that does not exist.
**Fix:** Remove the stale entry from marketplace.json.

### Step 7: Validate JSON

Confirm `.claude-plugin/marketplace.json` is well-formed JSON. Confirm each plugin.json is well-formed JSON.

### Step 8: Check for Duplicates

Ensure no two marketplace entries share the same `name`.

### Step 9: Report

Summarize all findings grouped by issue type, listing what was found and what was fixed.
