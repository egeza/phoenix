process RESOLVE_SRA_ACCESSIONS {
    tag "${accession}"
    label 'process_single'
    maxForks 6
    container 'quay.io/biocontainers/entrez-direct@sha256:ccafbda537a8ab77206758c91a383defe0ea5007365b526aa89db3cfbf451d51'

    input:
    val(accession)

    output:
    stdout emit: run_ids
    path("versions.yml"), emit: versions

    script:
    def container = task.container.toString() - "quay.io/biocontainers/entrez-direct@"
    def sanitized = accession.replaceAll(/[^A-Za-z0-9._-]/, "_")
    """
    set -euo pipefail

    accession="${accession}"
    accession=\$(printf '%s' "\${accession}" | tr -d '\\r\\n')
    resolved_runs="${sanitized}_runs.txt"

    case "\${accession}" in
        SRR*|ERR*|DRR*|CRR*)
            printf "%s\\n" "\${accession}" > "\${resolved_runs}"
            ;;
        *)
            esearch -db sra -query "\${accession}" | efetch -format runinfo > "${sanitized}_runinfo.csv"
            python3 - <<'PY'
from pathlib import Path
import csv
import sys

runinfo = Path("${sanitized}_runinfo.csv")
output = Path("${sanitized}_runs.txt")

if not runinfo.exists():
    sys.exit("No runinfo returned for accession")

runs = []
with runinfo.open() as handle:
    reader = csv.DictReader(handle)
    for row in reader:
        run = (row.get("Run") or "").strip()
        if run:
            runs.append(run)

if not runs:
    sys.exit("No run accessions resolved for ${accession}")

with output.open("w") as out_handle:
    for run in sorted(set(runs)):
        out_handle.write(f"{run}\\n")
PY
            ;;
    esac

    cat "\${resolved_runs}"

    cat <<END_VERSIONS > versions.yml
"${task.process}":
    esearch: \$(esearch -version)
    esearch_container: ${container}
    input_accession: "${accession}"
END_VERSIONS
    """
}

