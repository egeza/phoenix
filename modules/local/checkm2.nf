process CHECKM2 {
    tag "${meta.id}"
    label 'process_medium'
    container 'staphb/checkm2@sha256:60d8ac58e016349a856fb7b443dd422ba69bae3f40e0dad83460d25ecf71101e'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.checkm2.tsv"), emit: report
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def db_path = params.checkm2_db ?: ""
    def container_version = task.container.toString()
    """
    db_path="${db_path}"
    db_arg=""
    if [ -n "$db_path" ]; then
        if [ -d "$db_path" ]; then
            for candidate in "$db_path"/*.dmnd; do
                if [ -f "$candidate" ]; then
                    db_path="$candidate"
                    break
                fi
            done
        fi
        if [ -f "$db_path" ]; then
            db_arg="--database_path $db_path"
        else
            echo "CheckM2 database not found at: $db_path" >&2
            exit 1
        fi
    fi

    checkm2 predict \\
        --input ${fasta} \\
        --output-directory checkm2_out \\
        --threads ${task.cpus} \\
        ${db_arg} \\
        ${args}

    report_file=""
    for candidate in checkm2_out/*quality_report*.tsv checkm2_out/*quality_report*.txt; do
        if [ -f "\$candidate" ]; then
            report_file="\$candidate"
            break
        fi
    done

    if [ -z "\$report_file" ]; then
        echo "CheckM2 quality report not found in checkm2_out" >&2
        exit 1
    fi

    cp "\$report_file" ${prefix}.checkm2.tsv

    checkm2_version=\$(checkm2 --version 2>&1 | head -n 1 | tr -d '\\r' | sed 's/"/\\\\"/g')

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkm2: "\${checkm2_version}"
        checkm2_container: "${container_version}"
    END_VERSIONS
    """
}
