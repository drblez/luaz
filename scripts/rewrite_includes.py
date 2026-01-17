#!/usr/bin/env python3
import argparse
import csv
import re
from pathlib import Path

INCLUDE_RE = re.compile(r'^(\s*#\s*include\s*)"([^"]+)"', re.M)


def load_map(csv_path: Path):
    by_name = {}
    collisions = {}
    with csv_path.open(newline='', encoding='utf-8') as f:
        rd = csv.DictReader(f)
        for row in rd:
            rel = row['relative_path']
            member = row['member']
            name = Path(rel).name
            if name in by_name and by_name[name] != member:
                collisions.setdefault(name, set()).update({by_name[name], member})
            else:
                by_name[name] = member
    if collisions:
        msg = "Ambiguous header names in map:\n" + "\n".join(
            f"  {k}: {sorted(list(v))}" for k, v in sorted(collisions.items())
        )
        raise SystemExit(msg)
    return by_name


def should_skip(path: Path):
    parts = path.parts
    return 'third_party' in parts or path.name.startswith('.')


def rewrite_file(path: Path, name_map: dict) -> bool:
    text = path.read_text(errors='ignore')
    changed = False

    def repl(match):
        nonlocal changed
        prefix, header = match.group(1), match.group(2)
        base = Path(header).name
        member = name_map.get(base)
        if member:
            changed = True
            return f'{prefix}"{member}"'
        return match.group(0)

    new_text = INCLUDE_RE.sub(repl, text)
    if changed and new_text != text:
        path.write_text(new_text)
    return changed


def main():
    ap = argparse.ArgumentParser(description='Rewrite quoted #include headers to PDS member names.')
    ap.add_argument('--map', required=True, help='CSV map with relative_path,member')
    ap.add_argument('--root', default='.', help='Root to scan')
    ap.add_argument('--ext', action='append', default=['.c', '.h'], help='Extensions to scan')
    args = ap.parse_args()

    name_map = load_map(Path(args.map))

    changed_files = []
    for p in Path(args.root).rglob('*'):
        if not p.is_file() or p.suffix not in args.ext:
            continue
        if should_skip(p):
            continue
        if rewrite_file(p, name_map):
            changed_files.append(p)

    print(f"updated {len(changed_files)} files")
    for p in changed_files:
        print(p.as_posix())

if __name__ == '__main__':
    main()
