#!/usr/bin/env python3
"""
Backfill MLST_Scheme_1 and MLST_1 in Phoenix_Summary.tsv from per-sample mlst/*_combined.tsv files.

Use when the pipeline reported Unknown for ST but individual sample folders contain
valid *_combined.tsv (e.g. for H. pylori or large assembly-only runs).

Usage:
  backfill_mlst_to_summary.py --summary Phoenix_Summary.tsv --phx_output /path/to/phx_output
  backfill_mlst_to_summary.py --summary phx_output/Phoenix_Summary.tsv --phx_output phx_output

Output: writes <summary_path>.backfill_mlst.tsv (default) or --out path.
"""

import argparse
import csv
from pathlib import Path


def get_version():
    return "1.0.0"


def parse_args():
    p = argparse.ArgumentParser(
        description="Backfill MLST columns in Phoenix_Summary from per-sample mlst/*_combined.tsv"
    )
    p.add_argument(
        "--summary",
        required=True,
        help="Path to Phoenix_Summary.tsv",
    )
    p.add_argument(
        "--phx_output",
        required=True,
        help="Path to Phoenix output directory containing sample subdirs (e.g. phx_output)",
    )
    p.add_argument(
        "--out",
        default=None,
        help="Output TSV path (default: <summary>.backfill_mlst.tsv)",
    )
    p.add_argument("--version", action="version", version=get_version())
    return p.parse_args()


def find_combined_tsv(phx_output_dir: Path, wgs_id: str):
    """Return path to mlst/*_combined.tsv for sample WGS_ID, or None."""
    sample_dir = phx_output_dir / wgs_id
    if not sample_dir.is_dir():
        return None
    mlst_dir = sample_dir / "mlst"
    if not mlst_dir.is_dir():
        return None
    candidates = list(mlst_dir.glob("*_combined.tsv"))
    return candidates[0] if candidates else None


def read_st_from_combined(combined_path: Path):
    """
    Read first data row from *_combined.tsv.
    Returns (database, st) e.g. ('hpylori', '181') or (None, None).
    """
    try:
        with open(combined_path, "r", encoding="utf-8", newline="") as f:
            reader = csv.reader(f, delimiter="\t")
            header = next(reader, None)
            if not header:
                return None, None
            # Expected: WGS_ID, Source, Pulled_on, Database, ST, locus_1, ...
            idx_db = idx_st = None
            for i, col in enumerate(header):
                if col.strip().lower() == "database":
                    idx_db = i
                if col.strip().upper() == "ST":
                    idx_st = i
            if idx_db is None or idx_st is None:
                return None, None
            row = next(reader, None)
            if not row or len(row) <= max(idx_db, idx_st):
                return None, None
            db = (row[idx_db] or "").strip()
            st = (row[idx_st] or "").strip()
            if not db and not st:
                return None, None
            return db, st
    except Exception:
        return None, None


def main():
    args = parse_args()
    summary_path = Path(args.summary)
    phx_output = Path(args.phx_output)

    if not summary_path.is_file():
        raise SystemExit(f"Summary file not found: {summary_path}")

    out_path = Path(args.out) if args.out else summary_path.parent / f"{summary_path.stem}.backfill_mlst.tsv"

    rows = []
    header = None
    col_wgs = col_scheme1 = col_st1 = None

    with open(summary_path, "r", encoding="utf-8", newline="") as f:
        reader = csv.reader(f, delimiter="\t")
        header = next(reader)
        # Find column indices
        for i, h in enumerate(header):
            h = (h or "").strip()
            if h == "WGS_ID":
                col_wgs = i
            elif h == "MLST_Scheme_1":
                col_scheme1 = i
            elif h == "MLST_1":
                col_st1 = i
        if col_wgs is None:
            raise SystemExit("Column WGS_ID not found in summary.")
        if col_scheme1 is None or col_st1 is None:
            raise SystemExit("Columns MLST_Scheme_1 and/or MLST_1 not found.")

        for row in reader:
            if len(row) <= max(col_wgs, col_scheme1, col_st1):
                rows.append(row)
                continue
            wgs_id = (row[col_wgs] or "").strip()
            if not wgs_id:
                rows.append(row)
                continue
            combined = find_combined_tsv(phx_output, wgs_id)
            if not combined:
                rows.append(row)
                continue
            db, st = read_st_from_combined(combined)
            if db is None and st is None:
                rows.append(row)
                continue
            # Extend row if needed so we can set scheme and ST
            while len(row) <= max(col_scheme1, col_st1):
                row.append("")
            if db is not None:
                row[col_scheme1] = db
            if st is not None and st not in ("-", "Unknown", ""):
                row[col_st1] = f"ST{st}" if st.isdigit() else st
            rows.append(row)

    with open(out_path, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, delimiter="\t")
        w.writerow(header)
        w.writerows(rows)

    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
