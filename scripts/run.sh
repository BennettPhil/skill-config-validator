#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: run.sh --format FORMAT [OPTIONS]"
  echo ""
  echo "Validate a configuration file for syntax errors and common issues."
  echo "Reads from stdin."
  echo ""
  echo "Options:"
  echo "  --format FORMAT        Config format: json, yaml, toml, ini, env"
  echo "  --output FORMAT        Output format: json (default), text"
  echo "  --check-duplicates     Warn on duplicate keys (JSON)"
  echo "  --help                 Show this help"
}

FORMAT=""
OUTPUT="json"
CHECK_DUPES="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --help) usage; exit 0 ;;
    --format) FORMAT="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --check-duplicates) CHECK_DUPES="true"; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

INPUT=$(cat)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "$INPUT" | python3 "$SCRIPT_DIR/_validate.py" "$FORMAT" "$OUTPUT" "$CHECK_DUPES"
