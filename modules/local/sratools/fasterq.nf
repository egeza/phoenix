process SRATOOLS_FASTERQDUMP {
    tag "${meta.id}"
    label 'process_low'
    // benpasto/sratools
    container "benpasto/sratools:latest"

    input:
    tuple val(meta), path(sra_folder)

    output:
    tuple val(meta), path("*_*.fastq.gz"), emit: reads // we don't want the accession.fastq just the forward and reverse
    path("versions.yml"),                  emit: versions

    script:
    //define variables
    def args = task.ext.args ?: ''
    def run_accession = sra_folder.toString() - "_Folder"
    def container = task.container.toString()
    """
    # change folder name back for fasterq-dump to find
    mv ${sra_folder} ${run_accession}

    fasterq-dump \\
        $args \\
        --threads $task.cpus \\
        ${run_accession}

    gzip ${run_accession}_1.fastq
    gzip ${run_accession}_2.fastq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sratools: \$(fasterq-dump --version 2>&1 | sed 's/fasterq-dump : //' | awk 'NF' )
        sratools_container: ${container}
    END_VERSIONS
    """
}