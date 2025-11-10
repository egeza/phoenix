process ENTREZDIRECT_ESEARCH {
    tag "${meta.id}"
    label 'process_single'
    maxForks 3
    // v16.2--he881be0_1
    container 'quay.io/biocontainers/entrez-direct:16.2--he881be0_1'

    input:
    tuple val(meta), path(sra_folder)

    output:
    tuple val(meta), path("*_sra_metadata.csv"), emit: metadata_csv
    path("versions.yml"),                        emit: versions

    script:
    def container = task.container.toString()
    """
    esearch \\
        -db sra \\
        -query ${meta.id} | \\
        efetch -format runinfo > ${meta.id}_sra_metadata.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        esearch: \$(esearch -version)
        esearch_container: ${container}
    END_VERSIONS
    """
}