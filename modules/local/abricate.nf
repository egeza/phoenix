process ABRICATE {
    tag "${meta.id}"
    label 'process_medium'
    // abricate v1.2.0
    container 'staphb/abricate@sha256:559c16a1817d53fe4ddbd68ff4810245cd501e15606bb38e5e0f85e5103b4860'

    input:
    tuple val(meta), path(fasta), val(db_name)

    output:
    tuple val(meta), path("*.abricate.tsv"), emit: report
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def datadir = params.abricate_db_dir ? "--datadir ${params.abricate_db_dir}" : ""
    def minid = params.abricate_minid ?: 90
    def mincov = params.abricate_mincov ?: 60
    def container_version = task.container.toString() - "quay.io/biocontainers/abricate:"
    """
    abricate \\
        ${datadir} \\
        --db ${db_name} \\
        --minid ${minid} \\
        --mincov ${mincov} \\
        ${args} \\
        ${fasta} > ${prefix}__${db_name}.abricate.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: \$(abricate --version 2>&1 | head -n 1 | tr -d '\\r')
        abricate_container: ${container_version}
        database: ${db_name}
        minid: ${minid}
        mincov: ${mincov}
    END_VERSIONS
    """
}
