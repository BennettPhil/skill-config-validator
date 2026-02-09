#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0
TOTAL=0

pass() { ((PASS++)); ((TOTAL++)); echo "  PASS: $1"; }
fail() { ((FAIL++)); ((TOTAL++)); echo "  FAIL: $1 -- $2"; }

assert_eq() {
  local description="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    pass "$description"
  else
    fail "$description" "expected '$expected', got '$actual'"
  fi
}

assert_exit_code() {
  local description="$1" expected_code="$2"
  shift 2
  set +e
  "$@" >/dev/null 2>&1
  local actual_code=$?
  set -e
  if [ "$expected_code" -eq "$actual_code" ]; then
    pass "$description"
  else
    fail "$description" "expected exit code $expected_code, got $actual_code"
  fi
}

assert_contains() {
  local description="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF -- "$needle"; then
    pass "$description"
  else
    fail "$description" "output does not contain '$needle'"
  fi
}

echo "Running tests for: config-validator"
echo "================================"

# --- Happy path tests ---
echo ""
echo "Happy path:"

# Valid JSON
RESULT=$(echo '{"key": "value", "count": 42}' | "$SCRIPT_DIR/run.sh" --format json)
assert_contains "valid JSON passes" '"valid": true' "$RESULT"

# Valid YAML
RESULT=$(printf 'name: test\nport: 8080' | "$SCRIPT_DIR/run.sh" --format yaml)
assert_contains "valid YAML passes" '"valid": true' "$RESULT"

# Valid env
RESULT=$(printf 'DB_HOST=localhost\nDB_PORT=5432' | "$SCRIPT_DIR/run.sh" --format env)
assert_contains "valid env passes" '"valid": true' "$RESULT"

# Valid INI
RESULT=$(printf '[database]\nhost = localhost\nport = 5432' | "$SCRIPT_DIR/run.sh" --format ini)
assert_contains "valid INI passes" '"valid": true' "$RESULT"

# --- Edge case tests ---
echo ""
echo "Edge cases:"

# Empty input
RESULT=$(echo "" | "$SCRIPT_DIR/run.sh" --format json 2>&1 || true)
assert_contains "empty input detected" "warning" "$RESULT"

# JSON with trailing comma (common mistake)
RESULT=$(printf '{"a": 1,}' | "$SCRIPT_DIR/run.sh" --format json 2>&1 || true)
assert_contains "trailing comma detected" "error" "$RESULT"

# Duplicate keys warning
RESULT=$(printf '{"a": 1, "a": 2}' | "$SCRIPT_DIR/run.sh" --format json --check-duplicates 2>&1)
assert_contains "duplicate keys warned" "duplicate" "$RESULT"

# --- Error case tests ---
echo ""
echo "Error cases:"

# Invalid JSON
assert_exit_code "invalid JSON exits non-zero" 1 bash -c "echo 'not json at all' | '$SCRIPT_DIR/run.sh' --format json"

# Invalid YAML (tab indentation)
RESULT=$(printf 'name:\n\t- bad indent' | "$SCRIPT_DIR/run.sh" --format yaml 2>&1 || true)
assert_contains "tab indent warning" "warning" "$RESULT"

# Help flag works
RESULT=$("$SCRIPT_DIR/run.sh" --help 2>&1)
assert_contains "help flag works" "Usage" "$RESULT"

# JSON output format
RESULT=$(echo '{"a": 1}' | "$SCRIPT_DIR/run.sh" --format json --output json)
assert_contains "JSON output has valid key" '"valid"' "$RESULT"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed, $TOTAL total"
[ "$FAIL" -eq 0 ] || exit 1
