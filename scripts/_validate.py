import sys, json, re

content = sys.stdin.read()
fmt = sys.argv[1] if len(sys.argv) > 1 else ""
output_fmt = sys.argv[2] if len(sys.argv) > 2 else "json"
check_dupes = sys.argv[3] == "true" if len(sys.argv) > 3 else False

errors = []
warnings = []
valid = True

if not content.strip():
    warnings.append("Input is empty")
    result = {"valid": True, "format": fmt or "unknown", "errors": errors, "warnings": warnings}
    if output_fmt == "json":
        print(json.dumps(result, indent=2))
    else:
        print("warning: Input is empty")
    sys.exit(0)

# Auto-detect format if not specified
if not fmt:
    try:
        json.loads(content)
        fmt = "json"
    except Exception:
        fmt = "unknown"

if fmt == "json":
    if check_dupes:
        import collections
        def check_duplicate_keys(pairs):
            key_count = collections.Counter(k for k, v in pairs)
            dupes = [k for k, c in key_count.items() if c > 1]
            for d in dupes:
                warnings.append(f'duplicate key: "{d}"')
            return dict(pairs)
        try:
            json.loads(content, object_pairs_hook=check_duplicate_keys)
        except json.JSONDecodeError:
            pass

    try:
        json.loads(content)
    except json.JSONDecodeError as e:
        valid = False
        msg = str(e)
        if "Expecting" in msg and content.rstrip().endswith(",}"):
            errors.append(f"error: trailing comma before closing brace (line {e.lineno})")
        elif "Expecting" in msg and content.rstrip().endswith(",]"):
            errors.append(f"error: trailing comma before closing bracket (line {e.lineno})")
        else:
            errors.append(f"error: {msg}")

elif fmt == "yaml":
    import yaml
    for i, line in enumerate(content.split("\n"), 1):
        if "\t" in line and not line.strip().startswith("#"):
            warnings.append(f"warning: tab character found on line {i} (YAML uses spaces for indentation)")
    try:
        yaml.safe_load(content)
    except yaml.YAMLError as e:
        valid = False
        errors.append(f"error: {e}")

elif fmt == "toml":
    try:
        try:
            import tomllib
        except ImportError:
            import tomli as tomllib
        tomllib.loads(content)
    except Exception as e:
        valid = False
        errors.append(f"error: {e}")

elif fmt == "ini":
    import configparser
    parser = configparser.ConfigParser()
    try:
        parser.read_string(content)
    except configparser.Error as e:
        valid = False
        errors.append(f"error: {e}")

elif fmt == "env":
    for i, line in enumerate(content.split("\n"), 1):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        line_clean = line.removeprefix("export").strip()
        if "=" not in line_clean:
            errors.append(f"error: line {i}: missing = in key-value pair")
            valid = False
        else:
            key = line_clean.split("=")[0].strip()
            if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", key):
                warnings.append(f'warning: line {i}: key "{key}" contains non-standard characters')

else:
    errors.append(f'error: unknown format "{fmt}". Use --format to specify.')
    valid = False

result = {"valid": valid, "format": fmt, "errors": errors, "warnings": warnings}

if output_fmt == "json":
    print(json.dumps(result, indent=2))
else:
    if valid and not warnings:
        print(f"Valid {fmt}")
    elif valid and warnings:
        for w in warnings:
            print(w)
        print(f"Valid {fmt} (with warnings)")
    else:
        for e in errors:
            print(e)
        for w in warnings:
            print(w)
        print(f"Invalid {fmt}")

if not valid:
    sys.exit(1)
