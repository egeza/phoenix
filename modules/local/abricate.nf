process ABRICATE {
    tag "${meta.id}"
    label 'process_low'
    container 'staphb/abricate:latest'

    input:
    tuple val(meta), path(fasta), val(fairy_outcome)
    val(db_name)

    output:
    tuple val(meta), path("*.tab"), emit: report
    path "versions.yml", emit: versions

    when:
    "${fairy_outcome[4]}" == "PASSED: More than 0 scaffolds in ${meta.id} after filtering."

    script:
    def args    = task.ext.args   ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def container = task.container?.toString() ?: ''
    def output_prefix = "${prefix}_${db_name}"
    """
    set -euo pipefail

    input_fasta="${fasta}"
    cleanup=false

    if [[ "${fasta}" == *.gz ]]; then
        gunzip -c "${fasta}" > ${prefix}.abricate.tmp.fa
        input_fasta="${prefix}.abricate.tmp.fa"
        cleanup=true
    fi

    abricate \
        --db ${db_name} \
        ${args} \
        "\${input_fasta}" \
        > ${output_prefix}.tab

    if [[ "\${cleanup}" == true ]]; then
        rm -f ${prefix}.abricate.tmp.fa
    fi

    abr_version=\$(abricate --version 2>&1 | awk '{print \$2}')

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: \${abr_version}
        abricate_container: ${container}
        database: ${db_name}
    END_VERSIONS
    """
}
