---
name: config-validator
description: Validate configuration files for syntax errors, common mistakes, and best practice violations.
version: 0.1.0
license: Apache-2.0
---

# Config Validator

Validate configuration files for syntax correctness, common mistakes, and best practice violations across JSON, YAML, TOML, INI, and .env formats.

## Purpose

Catch config file issues before deployment. This skill validates syntax, warns about common pitfalls (duplicate keys, tab indentation in YAML, unquoted special characters in .env), and provides actionable error messages.

## Contract

- Valid configs exit 0 with `{"valid": true, ...}`
- Invalid configs exit 1 with `{"valid": false, "errors": [...]}`
- Warnings (non-fatal issues) are included in the `warnings` array
- Supports JSON, YAML, INI, and .env formats

## Inputs

- Config text via stdin
- `--format FORMAT` — specify format (json, yaml, toml, ini, env)
- `--output json|text` — output format (default: json)
- `--check-duplicates` — warn on duplicate keys (JSON)
- `--help` — show usage

## Outputs

JSON object with:
- `valid` (boolean) — whether the config is syntactically valid
- `format` (string) — detected or specified format
- `errors` (array) — list of error descriptions
- `warnings` (array) — list of warning descriptions

## Error Handling

- Missing `--format` attempts auto-detection
- Empty input produces a warning, not an error
- Parse failures produce descriptive error messages with line numbers when possible

## Testing

Run `scripts/test.sh` to verify all contracts. Tests cover:
- Happy path: valid configs for each format
- Edge cases: empty input, trailing commas, duplicate keys
- Error cases: invalid syntax, tab indentation, bad format
