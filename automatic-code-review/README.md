# Automatic Code Review

Semantic code review on session stop. Tracks file modifications and reviews against your project-specific rules.

## Installation

See main [README](../README.md#installation) for marketplace setup and plugin installation.

## Setup

**Auto-initializes on first hook run.**

Creates/updates:
- `.claude/settings.json` - Adds `automaticCodeReview` configuration
- `.claude/automatic-code-review/rules.md` - Default semantic rules

Customize `.claude/automatic-code-review/rules.md` for your project.

## Configuration

Settings in `.claude/settings.json`:
```json
{
  "automaticCodeReview": {
    "enabled": true,
    "fileExtensions": ["ts", "tsx"],
    "rulesFile": ".claude/automatic-code-review/rules.md"
  }
}
```

Set `"enabled": false` to disable for a project.

## How It Works

1. PostToolUse hook logs file modifications to `/tmp/event-log-{SESSION_ID}.jsonl`
2. Stop hook checks for new files since last review
3. Triggers `automatic-code-reviewer` agent with file list
4. Agent reads rules from configured rulesFile and enforces them

## Requirements

- `jq` - Install with `brew install jq` or `apt-get install jq`
