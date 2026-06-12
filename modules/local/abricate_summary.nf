/*
    Summarise multiple Abricate result files into one TSV using abricate --summary.
    Used for both virulence (VFDB/ecoli_vf) and plasmid (plasmidfinder) results.
*/
process ABRICATE_SUMMARY {
    tag "${meta.id}"
    label 'process_single'
    container 'staphb/abricate@sha256:559c16a1817d53fe4ddbd68ff4810245cd501e15606bb38e5e0f85e5103b4860'

    input:
    tuple val(meta), path(report)

    output:
    tuple val(meta), path("*.abricate_summary.tsv"), emit: summary
    path("versions.yml"),                            emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def db_name = report.name.tokenize('__')[1]?.tokenize('.')[0] ?: "unknown"
    """
    abricate --summary ${report} > ${prefix}__${db_name}.abricate_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: \$(abricate --version 2>&1 | head -n 1 | tr -d '\\r')
        database: ${db_name}
    END_VERSIONS
    """
}
