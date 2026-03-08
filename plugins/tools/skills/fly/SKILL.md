---
name: fly
description: >
  Manage and operate Fly.io applications using the `fly` CLI (flyctl). Covers deployment, logs,
  scaling, secrets, machines, volumes, postgres, SSH, proxying, health checks, certificates, IPs,
  releases, config, and diagnostics. Use this skill whenever the user mentions Fly.io, flyctl,
  fly deploy, fly machines, fly logs, fly scale, fly secrets, or any Fly.io infrastructure
  operations -- even if they just say "deploy" or "check logs" in a project that has a fly.toml.
  Also trigger when the user references fly.toml configuration, Fly regions, Fly volumes, or
  Fly Postgres clusters.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

# Fly.io Operations Skill

You are an expert at managing Fly.io applications using the `fly` CLI. This skill gives you
the knowledge to run any fly command correctly and safely.

## Safety Rules

These rules are non-negotiable:

1. **Read-only by default.** Always prefer read-only commands (list, status, show, logs) unless
   the user explicitly asks for a mutation (deploy, scale, destroy, etc.).
2. **Confirm before destructive actions.** Before running any of these, state what you're about
   to do and ask for confirmation:
   - `fly apps destroy`
   - `fly machine destroy` / `fly machine kill`
   - `fly volumes destroy`
   - `fly secrets unset`
   - `fly certs remove`
   - `fly postgres` write operations (create, failover, import)
   - `fly ips release`
   - `fly scale count 0`
   - Any `--force` or `--yes` flag
3. **Never run `fly deploy` without the user asking.** Deploying pushes code to production.
   Always confirm the app name and working directory before deploying.
4. **Use `--json` or `-j` when available** to get structured output you can parse and summarize.
   Present the results in a clean, readable format to the user.
5. **Use `--no-tail` for logs** so the command returns instead of streaming indefinitely.

## Context Detection

When starting, look for a `fly.toml` in the current directory or project root to identify the
app name and configuration. If found, read it to understand the app setup. If no fly.toml exists
and no `-a` flag is provided, ask the user which app to target.

## Command Reference

### App Lifecycle

| Task | Command |
|---|---|
| List all apps | `fly apps list` |
| App status | `fly status -a APP` or `fly status` (uses fly.toml) |
| Deploy | `fly deploy` (from dir with fly.toml) |
| Deploy specific dir | `fly deploy PATH` |
| Restart app | `fly apps restart APP` |
| Open in browser | `fly apps open -a APP` |
| View releases | `fly releases -a APP --json` |
| Show services | `fly services list -a APP` |

### Logs & Monitoring

| Task | Command |
|---|---|
| Recent logs | `fly logs -a APP --no-tail` |
| Logs for region | `fly logs -a APP -r REGION --no-tail` |
| Logs for machine | `fly logs -a APP --machine MACHINE_ID --no-tail` |
| JSON logs | `fly logs -a APP --no-tail -j` |
| Health checks | `fly checks list -a APP` |
| Dashboard | `fly dashboard -a APP` |
| Diagnostics | `fly doctor -a APP` |

### Machines

| Task | Command |
|---|---|
| List machines | `fly machine list -a APP` |
| Machine status | `fly machine status MACHINE_ID -a APP` |
| Start machine | `fly machine start MACHINE_ID -a APP` |
| Stop machine | `fly machine stop MACHINE_ID -a APP` |
| Restart machine | `fly machine restart MACHINE_ID -a APP` |
| Suspend machine | `fly machine suspend MACHINE_ID -a APP` |
| Clone machine | `fly machine clone MACHINE_ID -a APP` |
| Run command on machine | `fly machine exec MACHINE_ID "CMD" -a APP` |
| Cordon (drain traffic) | `fly machine cordon MACHINE_ID -a APP` |
| Uncordon | `fly machine uncordon MACHINE_ID -a APP` |
| Destroy machine | `fly machine destroy MACHINE_ID -a APP` (CONFIRM FIRST) |

### Scaling

| Task | Command |
|---|---|
| Show current scale | `fly scale show -a APP` |
| Set VM size | `fly scale vm SIZE -a APP` (e.g., shared-cpu-1x, performance-1x) |
| Set memory | `fly scale memory SIZE_MB -a APP` |
| Set machine count | `fly scale count N -a APP` |
| Available VM sizes | `fly platform vm-sizes` |

### Secrets

| Task | Command |
|---|---|
| List secrets | `fly secrets list -a APP` |
| Set secret | `fly secrets set KEY=VALUE -a APP` |
| Set multiple | `fly secrets set K1=V1 K2=V2 -a APP` |
| Unset secret | `fly secrets unset KEY -a APP` (CONFIRM FIRST) |
| Import from stdin | `cat .env \| fly secrets import -a APP` |

### Volumes

| Task | Command |
|---|---|
| List volumes | `fly volumes list -a APP` |
| Show volume | `fly volumes show VOL_ID -a APP` |
| Create volume | `fly volumes create NAME --region REGION --size SIZE_GB -a APP` |
| Extend volume | `fly volumes extend VOL_ID --size SIZE_GB -a APP` |
| Volume snapshots | `fly volumes snapshots list VOL_ID -a APP` |
| Destroy volume | `fly volumes destroy VOL_ID -a APP` (CONFIRM FIRST) |

### Configuration

| Task | Command |
|---|---|
| Show config | `fly config show -a APP` |
| Show env vars | `fly config env -a APP` |
| Validate config | `fly config validate` (from dir with fly.toml) |
| Save config | `fly config save -a APP` |

### Networking

| Task | Command |
|---|---|
| List IPs | `fly ips list -a APP` |
| Allocate IPs | `fly ips allocate -a APP` |
| Allocate IPv4 | `fly ips allocate-v4 -a APP` |
| Allocate IPv6 | `fly ips allocate-v6 -a APP` |
| Private IPs | `fly ips private -a APP` |
| Release IP | `fly ips release IP_ADDRESS -a APP` (CONFIRM FIRST) |
| Proxy local port | `fly proxy LOCAL:REMOTE -a APP` |

### Certificates

| Task | Command |
|---|---|
| List certs | `fly certs list -a APP` |
| Add cert | `fly certs add HOSTNAME -a APP` |
| Check cert | `fly certs check HOSTNAME -a APP` |
| Remove cert | `fly certs remove HOSTNAME -a APP` (CONFIRM FIRST) |

### Postgres

| Task | Command |
|---|---|
| List clusters | `fly postgres list` |
| Connect to DB | `fly postgres connect -a PG_APP` |
| Attach to app | `fly postgres attach PG_APP -a APP` |
| Detach from app | `fly postgres detach PG_APP -a APP` |
| List DBs | `fly postgres db list -a PG_APP` |
| List users | `fly postgres users list -a PG_APP` |
| Show config | `fly postgres config show -a PG_APP` |
| View events | `fly postgres events -a PG_APP` |
| Backup list | `fly postgres backup list -a PG_APP` |
| Failover | `fly postgres failover -a PG_APP` (CONFIRM FIRST) |

### SSH & Remote Access

| Task | Command |
|---|---|
| SSH console | `fly ssh console -a APP` |
| Run remote command | `fly ssh console -a APP -C "CMD"` |
| SFTP get file | `fly ssh sftp get /remote/path local/path -a APP` |
| SFTP put file | `fly ssh sftp shell -a APP` then `put local remote` |

### Platform & Auth

| Task | Command |
|---|---|
| List regions | `fly platform regions` |
| Platform status | `fly platform status` |
| VM sizes | `fly platform vm-sizes` |
| Current user | `fly auth whoami` |
| List orgs | `fly orgs list` |

## Common Workflows

### Check app health
```
fly status -a APP
fly checks list -a APP
fly logs -a APP --no-tail
```

### Debug a failing deploy
```
fly releases -a APP --json    # check recent releases
fly logs -a APP --no-tail     # check logs around failure
fly machine list -a APP       # check machine states
fly doctor -a APP             # run diagnostics
```

### Scale up for traffic
```
fly scale show -a APP         # see current config
fly scale vm performance-1x -a APP
fly scale count 3 -a APP
```

### Rotate a secret
```
fly secrets list -a APP       # verify secret exists
fly secrets set KEY=NEW_VALUE -a APP  # set triggers redeploy
```

## Output Formatting

When presenting fly command output to the user:
- Summarize machine lists as tables with ID, region, state, and image
- For logs, highlight errors and warnings
- For status, lead with the overall health (running/stopped/failed) and machine count
- For secrets, never display secret values -- only names and metadata
