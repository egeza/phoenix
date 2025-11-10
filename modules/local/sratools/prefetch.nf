process SRATOOLS_PREFETCH {
    tag "${sra_accession[0]}"
    label 'process_single'
    // benpasto/sratools
    container "benpasto/sratools:latest"

    input:
    val(sra_accession)

    output:
    path("*_Folder")    , emit: sra_folder
    path('versions.yml'), emit: versions

    script:
    //define variables
    def container = task.container.toString()
    """
    # fetch sras
    prefetch --verify yes ${sra_accession[0]}

    #move so we have some common name to collect output, indexing is just to get rid of [] around the run accession
    mv ${sra_accession[0]} ${sra_accession[0]}_Folder

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sratools: \$(prefetch --version 2>&1 | sed 's/prefetch : //' | awk 'NF')
        sratools_container: ${container}
    END_VERSIONS
    """
}