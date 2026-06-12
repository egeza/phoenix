process KAPTIVE {
    tag "${meta.id}"
    label 'process_medium'
    container 'staphb/kaptive@sha256:43e0226e46b9092222d34747c3cc7b179bbea5e2b3bebd701481137f1e85e452'

    input:
    tuple val(meta), path(fasta), path(db), val(db_name)

    output:
    tuple val(meta), path("*.kaptive.tsv"), emit: report
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def container_version = task.container.toString() - "quay.io/biocontainers/kaptive:"
    """
    kaptive.py \\
        --input ${fasta} \\
        --db ${db} \\
        --output ${prefix}__${db_name}.kaptive.tsv \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kaptive: \$(kaptive.py --version 2>&1 | head -n 1 | tr -d '\\r')
        kaptive_container: ${container_version}
        database: ${db_name}
    END_VERSIONS
    """
}
