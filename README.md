# Config Validator

Validate configuration files for syntax errors, common mistakes, and best practice violations.

## Prerequisites

- Python 3.6+
- PyYAML (`pip install pyyaml`)

## Usage

```bash
# Validate JSON
echo '{"key": "value"}' | ./scripts/run.sh --format json

# Validate YAML
cat config.yaml | ./scripts/run.sh --format yaml

# Check for duplicate keys
echo '{"a": 1, "a": 2}' | ./scripts/run.sh --format json --check-duplicates

# Text output
cat config.env | ./scripts/run.sh --format env --output text
```

## Test

```bash
./scripts/test.sh
```

## Testing Philosophy

Tests are written first and define the contract. The implementation exists to make the tests pass.
