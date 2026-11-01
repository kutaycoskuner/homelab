# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-28
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
"""
Copies values from an existing .tfvars file into other .tfvars files, key by key.

For every simple assignment in a target file (`key = "..."`, a number, true/false), the
value of the same key in the source file is written in its place; comments, map and list
openers (`stack_env = {`) and keys the source doesn't have are left as they are.

Exists for moving an OpenTofu setup to new files, e.g. from this repo's
tofu/<folder>/terraform.tfvars into a private repo's terraform.tfvars and
secrets.auto.tfvars (docs/terraform.md#your-own-values-in-a-private-repo): the targets are
copied from their .example files first, then filled here, so no secret has to be pasted by
hand or shown on screen.

Requires: Python 3.10+, standard library only.

Inputs -> outputs: one source .tfvars, one or more target .tfvars -> the targets with the
values filled in (after asking per file; --dry-run changes nothing).

Run: python scripts/copy_tfvars_values/copy_tfvars_values.py --help

Only key names and what happened are printed, never a value. A key that appears more than
once in the source (e.g. the same name in two maps) is left alone: which one is meant is
unclear.
"""

import argparse
import re
import sys
from pathlib import Path

# -----------------------------------------------------------------------------------------
#   settings
# -----------------------------------------------------------------------------------------

# indent, key, " = ", value (quoted string, number or bool), rest of the line (e.g. a comment)
ASSIGN = re.compile(r'^(\s*)(\w+)(\s*=\s*)("(?:[^"\\]|\\.)*"|-?\d+(?:\.\d+)?|true|false)(.*)$')
PLACEHOLDER = re.compile(r'"<[^">]+>"')


def parse_args() -> argparse.Namespace:
    """Defines the CLI; a bare run prints the help (no work without a command)."""
    parser = argparse.ArgumentParser(
        description=__doc__.strip().splitlines()[0],
        epilog="example (from the repo root):\n"
               "  python scripts/copy_tfvars_values/copy_tfvars_values.py --copy tofu/portainer/terraform.tfvars "
               "../my-homelab/tofu/portainer/terraform.tfvars ../my-homelab/tofu/portainer/secrets.auto.tfvars --dry-run",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--copy", nargs="+", metavar=("SOURCE", "TARGET"),
                        help="the source .tfvars, then one or more target .tfvars to fill")
    parser.add_argument("--dry-run", action="store_true",
                        help="only show which keys would be filled, change nothing")
    parser.add_argument("--yes", action="store_true",
                        help="write without asking per file")
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(0)
    args = parser.parse_args()
    if not args.copy or len(args.copy) < 2:
        parser.print_help()
        print("\nerror: --copy needs a source and at least one target", file=sys.stderr)
        sys.exit(2)
    return args


def read_source_values(path: Path) -> dict[str, list[str]]:
    """Every simple assignment in the source: key -> its values (more than one if repeated)."""
    values: dict[str, list[str]] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        m = ASSIGN.match(line)
        if m:
            values.setdefault(m.group(2), []).append(m.group(4))
    return values


def fill_lines(lines: list[str], source: dict[str, list[str]]) -> tuple[list[str], list[str]]:
    """Returns the target's lines with the source values in place, and one report line per key."""
    out, report = [], []
    for line in lines:
        m = ASSIGN.match(line)
        if m:
            key, current = m.group(2), m.group(4)
            found = source.get(key, [])
            if len(found) == 1 and found[0] != current:
                line = m.group(1) + key + m.group(3) + found[0] + m.group(5)
                report.append(f"{key}: filled")
            elif len(found) == 1:
                report.append(f"{key}: already the same")
            elif not found:
                report.append(f"{key}: not in the source, left as is")
            else:
                report.append(f"{key}: {len(found)} times in the source, left as is")
        out.append(line)
    return out, report


def confirm(question: str) -> bool:
    return input(f"{question} [y/N] ").strip().lower() == "y"


def main() -> int:
    # 1. read the command line and the source
    args = parse_args()
    source_path, targets = Path(args.copy[0]), [Path(t) for t in args.copy[1:]]
    if not source_path.is_file():
        print(f"error: source not found: {source_path}", file=sys.stderr)
        return 1
    source = read_source_values(source_path)
    print(f"source: {source_path} ({len(source)} keys)\n")

    # 2. per target: fill in memory, report, then write after asking
    for target in targets:
        print(target)
        if not target.is_file():
            print("  not found -- copy it from its .example first\n")
            continue
        raw = target.read_text(encoding="utf-8")
        newline = "\r\n" if "\r\n" in raw else "\n"
        lines, report = fill_lines(raw.replace("\r\n", "\n").split("\n"), source)
        for entry in report:
            print(f"  {entry}")
        left = len(PLACEHOLDER.findall("\n".join(lines)))
        print(f"  -> {left} <placeholder>(s) left after filling")

        changed = any(entry.endswith(": filled") for entry in report)
        if args.dry_run or not changed:
            print("  nothing written" + (" (dry run)" if args.dry_run and changed else "") + "\n")
            continue
        if args.yes or confirm(f"  write {target}?"):
            target.write_bytes(newline.join(lines).encode("utf-8"))
            print("  written\n")
        else:
            print("  skipped\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
