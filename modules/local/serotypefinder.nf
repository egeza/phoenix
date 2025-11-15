process SEROTYPEFINDER {
    tag "${meta.id}"
    label 'process_low'
    container 'staphb/serotypefinder:latest'

    input:
    tuple val(meta), path(fasta), val(fairy_outcome)
    path(db_path)

    output:
    tuple val(meta), path("${meta.id}_serotypefinder_summary.tsv"), emit: summary
    tuple val(meta), path("${meta.id}_serotypefinder_results.tar.gz"), emit: archive
    path("versions.yml"), emit: versions

    when:
    "${fairy_outcome[4]}" == "PASSED: More than 0 scaffolds in ${meta.id} after filtering."

    script:
    def args      = task.ext.args   ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    def container = task.container?.toString() ?: ''
    """
    set -euo pipefail

    workdir=\$(pwd)
    sero_outdir="\${prefix}_serotypefinder_output"
    mkdir -p "\${sero_outdir}"

    input_fasta="${fasta}"
    cleanup_fasta=false
    if [[ "${fasta}" == *.gz ]]; then
        gunzip -c "${fasta}" > "\${prefix}.serotypefinder.tmp.fa"
        input_fasta="\${prefix}.serotypefinder.tmp.fa"
        cleanup_fasta=true
    fi

    db_use="${db_path}"
    cleanup_db=false
    if [[ "${db_path}" == *.tar.gz ]]; then
        db_tmp="\${prefix}_serotypefinder_db"
        mkdir -p "\${db_tmp}"
        tar -xzf "${db_path}" -C "\${db_tmp}"
        db_use="\${workdir}/\${db_tmp}"
        cleanup_db=true
    fi

    if ! command -v serotypefinder.py >/dev/null 2>&1; then
        echo "ERROR: serotypefinder.py not found in PATH." >&2
        exit 1
    fi

    serotypefinder.py \\
        -i "\${input_fasta}" \\
        -o "\${sero_outdir}" \\
        -p "\${db_use}" \\
        ${args}

    export SEROTYPE_PREFIX="\${prefix}"
    export SEROTYPE_OUTDIR="\$(pwd)/\${sero_outdir}"
    python3 - <<'PY'
import csv
import os
from pathlib import Path

prefix = os.environ.get("SEROTYPE_PREFIX", "").strip()
outdir = Path(os.environ.get("SEROTYPE_OUTDIR", "."))
summary_path = Path(f"{prefix}_serotypefinder_summary.tsv")
results_candidates = [
    "results_tab.tsv",
    "results_tab.txt",
    "results_tab.csv",
    "results_tab.ssv"
]

records = []
results_file = None
for candidate in results_candidates:
    candidate_path = outdir / candidate
    if candidate_path.exists():
        results_file = candidate_path
        break

if results_file and results_file.stat().st_size > 0:
    with results_file.open() as handle:
        filtered_lines = [
            line for line in handle
            if line.strip() and not line.startswith("#")
        ]
    if filtered_lines:
        reader = csv.DictReader(filtered_lines, delimiter='\\t')
        for row in reader:
            parts = []
            for key, value in row.items():
                if value is None:
                    continue
                value = str(value).strip()
                if not value or value.lower() in {"nan", "none"}:
                    continue
                parts.append(f"{key}:{value}")
            if parts:
                records.append(" | ".join(parts))

call = "No hits detected"
notes = ""
if records:
    call = records[0]
    if len(records) > 1:
        notes = "; ".join(records[1:])

with summary_path.open("w", encoding="utf-8") as handle:
    handle.write("WGS_ID\\tSerotypeFinder_Call\\tSerotypeFinder_Notes\\n")
    handle.write(f"{prefix}\\t{call}\\t{notes}\\n")
PY

    tar -czf "\${prefix}_serotypefinder_results.tar.gz" -C "\${sero_outdir}" .

    if [[ "\${cleanup_fasta}" == true ]]; then
        rm -f "\${prefix}.serotypefinder.tmp.fa"
    fi
    if [[ "\${cleanup_db}" == true ]]; then
        rm -rf "\${prefix}_serotypefinder_db"
    fi

    serotype_version=\$(serotypefinder.py --version 2>/dev/null || echo "unknown")

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        serotypefinder: \${serotype_version}
        serotypefinder_container: ${container}
    END_VERSIONS
    """
}

