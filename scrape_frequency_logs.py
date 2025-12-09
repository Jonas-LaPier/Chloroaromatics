#!/usr/bin/env python3
"""Scan `frequency_logs` for dG and LUMO values and write CSV.

Outputs `frequency_logs/summary.csv` by default.

Assumptions:
- The "name" column is derived from the filename stem up to the last underscore
  (e.g. `foo_bar_Baz.log` -> `foo_bar`). Leading underscores are stripped; if
  result is empty the full stem is used as fallback.
- For dG we look for the last occurrence of the string
  "Sum of electronic and thermal Free Energies= " and capture the following
  numeric token.
- For LUMO we look for the last occurrence of the string
  "Alpha virt. eigenvalues --" and take the first numeric value that follows
  on that line.
"""
from pathlib import Path
import re
import csv
import argparse
import sys


DG_RE = re.compile(r"Sum of electronic and thermal Free Energies=\s*([+-]?\d+(?:\.\d*)?(?:[Ee][+-]?\d+)?)")
ALPHA_LINE_RE = re.compile(r"Alpha virt\. eigenvalues --(.*)")
NUMBER_RE = re.compile(r"[+-]?\d+(?:\.\d*)?(?:[Ee][+-]?\d+)?")


def extract_values(text: str):
    """Return (dG, lumo) strings or None if not found."""
    dgs = DG_RE.findall(text)
    dG = dgs[-1] if dgs else None

    lumo = None
    alpha_matches = list(ALPHA_LINE_RE.finditer(text))
    if alpha_matches:
        last = alpha_matches[-1].group(1)
        num_match = NUMBER_RE.search(last)
        if num_match:
            lumo = num_match.group(0)

    return dG, lumo


def derive_name_from_stem(stem: str) -> str:
    # take up to last underscore
    if "_" in stem:
        left = stem.rsplit("_", 1)[0]
    else:
        left = stem
    left = left.strip(" _")
    if not left:
        return stem
    return left


def main():
    p = argparse.ArgumentParser(description="Scrape dG and LUMO from frequency logs")
    p.add_argument("--input-dir", "-i", default="frequency_logs", help="Directory with log files")
    p.add_argument("--output", "-o", default="frequency_logs/summary.csv", help="CSV output file")
    p.add_argument("--ext", default=".log", help="File extension to include (default .log)")
    args = p.parse_args()

    in_dir = Path(args.input_dir)
    if not in_dir.exists() or not in_dir.is_dir():
        print(f"Input dir '{in_dir}' not found", file=sys.stderr)
        sys.exit(2)

    files = sorted(in_dir.glob(f"*{args.ext}"))
    rows = []

    for f in files:
        try:
            text = f.read_text(errors="ignore")
        except Exception as e:
            print(f"Warning: couldn't read {f}: {e}", file=sys.stderr)
            continue

        dG, lumo = extract_values(text)

        stem = f.stem
        name = derive_name_from_stem(stem)

        rows.append((name, dG if dG is not None else "", lumo if lumo is not None else ""))

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", newline="") as csvf:
        writer = csv.writer(csvf)
        writer.writerow(["Name", "dG", "LUMO"])
        for r in rows:
            writer.writerow(r)

    print(f"Wrote {len(rows)} rows to {out_path}")


if __name__ == "__main__":
    main()
