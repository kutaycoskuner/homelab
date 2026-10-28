# -----------------------------------------------------------------------------------------
#   author          : Kutay Coskuner
#   ai-contributors : Claude Opus 5.5 (claude-opus-5-5)
#   last update     : 2026-10-24
#   disclaimer      : Provided as is, without warranty of any kind; use at your own risk.
#                     Check outputs before relying on them.
# -----------------------------------------------------------------------------------------
"""
Creates and checks the local .env files from the committed .env.example files.

Finds every `.env.example` in the repo and compares it with the `.env` next to it:
missing file, missing keys (new in the example) or unknown keys (dropped from it).
`--sync` creates missing files and, per mismatch, offers replace / update / keep.

Exists because the real `.env` files are gitignored (docs/secrets-and-examples.md):
each is copied once, and goes stale whenever its example gains or drops a key.

Requires: Python 3.10+, standard library only; run from anywhere (paths are relative
to this file's folder).

Inputs -> outputs: */.env.example, */.env -> report; with --sync: new or updated .env,
the old one kept as .env.bak (gitignored).

Run: python main.py --help

Only key names are compared, never values: the values are the user's secrets and
differ from the placeholders on purpose.
"""

import argparse
import re
import shutil
import sys
from dataclasses import dataclass, field
from pathlib import Path

# -----------------------------------------------------------------------------------------
#   settings
# -----------------------------------------------------------------------------------------

REPO = Path(__file__).resolve().parent
EXAMPLE_NAME = ".env.example"
REAL_NAME = ".env"
SKIP_DIRS = {".git", ".venv", "venv", "node_modules", "__pycache__", ".temp", ".input", "_documentation"}
KEY_LINE = re.compile(r"^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=")


@dataclass
class Pair:
    example: Path
    real: Path
    missing: list[str] = field(default_factory=list)   # in the example, not in .env
    unknown: list[str] = field(default_factory=list)   # in .env, not in the example

    @property
    def name(self) -> str:
        return self.real.relative_to(REPO).as_posix()

    @property
    def status(self) -> str:
        if not self.real.exists():
            return "missing"
        return "differs" if (self.missing or self.unknown) else "ok"


# -----------------------------------------------------------------------------------------
#   setup
# -----------------------------------------------------------------------------------------

def find_examples(only: Path | None) -> list[Path]:
    """Every .env.example under the repo (or under `only`), skipping tool and private folders."""
    base = only or REPO
    found = []
    for path in sorted(base.rglob(EXAMPLE_NAME)):
        if not any(part in SKIP_DIRS for part in path.relative_to(REPO).parts[:-1]):
            found.append(path)
    return found


def build_parser(examples: list[Path]) -> argparse.ArgumentParser:
    listed = "\n".join(f"  {p.relative_to(REPO).as_posix()}" for p in examples) or "  none"
    parser = argparse.ArgumentParser(
        prog="main.py",
        description="Creates and checks the local .env files from the committed .env.example files.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=f"example files found now:\n{listed}\n\n"
               "examples:\n"
               "  python main.py --check                          report, write nothing\n"
               "  python main.py --sync                           create missing .env files, fix mismatches (asks per file)\n"
               "  python main.py --sync --dry-run                 show what --sync would do\n"
               "  python main.py --check --only stacks/cloudflared  one folder only\n\n"
               "details: docs/secrets-and-examples.md",
    )
    cmd = parser.add_argument_group("commands").add_mutually_exclusive_group()
    cmd.add_argument("--check", action="store_true", help="compare every .env with its .env.example; writes nothing")
    cmd.add_argument("--sync", action="store_true", help="create missing .env files and offer replace / update / keep for mismatches")
    opt = parser.add_argument_group("options")
    opt.add_argument("--only", type=Path, help="limit to one folder (now: whole repo)")
    opt.add_argument("--dry-run", action="store_true", help="with --sync: show what would happen, write nothing")
    return parser


def env_keys(path: Path) -> list[str]:
    """Key names in a dotenv file, in file order; comments and blank lines ignored."""
    keys = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.lstrip().startswith("#"):
            continue
        m = KEY_LINE.match(line)
        if m and m.group(1) not in keys:
            keys.append(m.group(1))
    return keys


def compare(example: Path) -> Pair:
    pair = Pair(example=example, real=example.with_name(REAL_NAME))
    if pair.real.exists():
        want, have = env_keys(example), env_keys(pair.real)
        pair.missing = [k for k in want if k not in have]
        pair.unknown = [k for k in have if k not in want]
    return pair


# -----------------------------------------------------------------------------------------
#   work
# -----------------------------------------------------------------------------------------

def report(pairs: list[Pair]) -> None:
    for p in pairs:
        line = f"{p.status:8} {p.name}"
        if p.missing:
            line += f"\n         missing keys (placeholders would be used): {', '.join(p.missing)}"
        if p.unknown:
            line += f"\n         unknown keys (not in the example): {', '.join(p.unknown)}"
        print(line)
    counts = {s: sum(p.status == s for p in pairs) for s in ("ok", "missing", "differs")}
    print(f"\n{len(pairs)} example files: {counts['ok']} ok, {counts['missing']} missing, {counts['differs']} differ")


def ask(prompt: str, choices: str) -> str:
    """One letter from `choices`, or "" without a usable terminal (Windows reports NUL as a tty, so EOF is caught too)."""
    if not sys.stdin.isatty():
        return ""
    while True:
        try:
            answer = input(prompt).strip().lower()[:1]
        except EOFError:
            print()
            return ""
        if answer in choices:
            return answer


def merged_text(pair: Pair) -> str:
    """The example's text with the user's lines for keys both files have; new keys keep their placeholder."""
    mine = {}
    for line in pair.real.read_text(encoding="utf-8").splitlines():
        m = KEY_LINE.match(line)
        if m and not line.lstrip().startswith("#"):
            mine.setdefault(m.group(1), line)
    raw = pair.example.read_bytes().decode("utf-8")
    newline = "\r\n" if "\r\n" in raw else "\n"
    out = []
    for line in raw.splitlines():
        m = KEY_LINE.match(line)
        out.append(mine.get(m.group(1), line) if m and not line.lstrip().startswith("#") else line)
    return newline.join(out) + newline


def backup(real: Path) -> Path:
    bak = real.with_name(real.name + ".bak")
    shutil.copyfile(real, bak)
    return bak


def sync(pairs: list[Pair], dry_run: bool) -> None:
    for p in pairs:
        if p.status == "ok":
            continue
        print(f"\n{p.status}: {p.name}")
        if p.status == "missing":
            if dry_run:
                print("  would offer to create it from the example")
                continue
            if ask(f"  create {p.name} from {EXAMPLE_NAME}? [y/n] ", "yn") == "y":
                shutil.copyfile(p.example, p.real)   # byte copy, so it diffs cleanly against later examples
                print(f"  created; now fill in the placeholders in {p.name}")
            else:
                print("  skipped, nothing written")
            continue

        if p.missing:
            print(f"  missing keys: {', '.join(p.missing)}")
        if p.unknown:
            print(f"  unknown keys: {', '.join(p.unknown)}")
        if dry_run:
            print("  would offer: replace / update / keep")
            continue
        print("  replace: fresh copy of the example (your values are lost, kept in .env.bak)")
        print("  update:  example's layout, your values kept, missing keys added as placeholders"
              + (", unknown keys dropped (kept in .env.bak)" if p.unknown else ""))
        print("  keep:    write nothing; asked again next time")
        choice = ask("  [r]eplace / [u]pdate / [k]eep? ", "ruk")
        if choice in ("r", "u"):
            bak = backup(p.real)
            if choice == "r":
                shutil.copyfile(p.example, p.real)
            else:
                p.real.write_bytes(merged_text(p).encode("utf-8"))
            print(f"  {'replaced' if choice == 'r' else 'updated'}; old file in {bak.relative_to(REPO).as_posix()}")
            if p.missing:
                print(f"  fill in: {', '.join(p.missing)}")
        else:
            print("  kept, nothing written" + ("" if choice else " (no terminal to ask)"))


# -----------------------------------------------------------------------------------------
#   main
# -----------------------------------------------------------------------------------------

def main(argv: list[str]) -> int:
    # 1. Find the example files, so the help can list them
    only = None
    if "--only" in argv and argv.index("--only") + 1 < len(argv):
        only = (Path.cwd() / argv[argv.index("--only") + 1]).resolve()
    parser = build_parser(find_examples(only if only and only.is_dir() else None))
    args = parser.parse_args(argv)

    # 2. No command word: print the help; with only options, also the command to add
    if not (args.check or args.sync):
        parser.print_help()
        if argv:
            command = "--sync" if args.dry_run else "--check"   # --dry-run only means something with --sync
            print(f"\nNothing run: add a command, e.g. python main.py {command} {' '.join(argv)}")
        return 2 if argv else 0
    if args.only and not (Path.cwd() / args.only).resolve().is_dir():
        print(f"--only: no such folder: {args.only}")
        return 2
    if args.dry_run and args.check:
        print("--dry-run only applies to --sync; --check never writes.")

    # 3. Compare every .env with its example
    pairs = [compare(e) for e in find_examples((Path.cwd() / args.only).resolve() if args.only else None)]
    report(pairs)

    # 4. --sync: create and fix, asking per file
    if args.sync:
        sync(pairs, args.dry_run)
        if args.dry_run:
            print("\nDry run: nothing written.")
    return 1 if args.check and any(p.status != "ok" for p in pairs) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
