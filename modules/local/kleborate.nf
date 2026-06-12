process KLEBORATE {
    tag "${meta.id}"
    label 'process_medium'
    container 'staphb/kleborate@sha256:7415777837f8fbfe7e8c222351834d5af0974ad8d37032e8c49e9036b2524b2a'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.kleborate.tsv"), emit: report
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: '-p kpsc --trim_headers'
    def prefix = task.ext.prefix ?: "${meta.id}"
    def container_version = task.container.toString() - "quay.io/biocontainers/kleborate:"
    """
    export TERM=xterm

    set +e
    kleborate \\
        -a ${fasta} \\
        -o . \\
        ${args} > ${prefix}.kleborate.tsv 2> ${prefix}.kleborate.stderr.log
    kleborate_status=\$?
    set -e

    if [ "\${kleborate_status}" -ne 0 ]; then
        cat ${prefix}.kleborate.stderr.log >&2
        exit "\${kleborate_status}"
    fi

    kleborate_version=\$(kleborate --version 2>&1 | head -n 1 | tr -d '\\r' | sed 's/"/\\\\"/g')

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kleborate: "\${kleborate_version}"
        kleborate_container: "${container_version}"
    END_VERSIONS
    """
}
