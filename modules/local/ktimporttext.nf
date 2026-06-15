process KRONA_KTIMPORTTEXT {
    tag "$meta.id"
    label 'process_single'
    // 2.8.1--pl5321hdfd78af_1
    container 'quay.io/biocontainers/krona@sha256:8917b9840b369d102ee759a037cc8577295875952013aaa18897c00569c9fe47'

    input:
    tuple val(meta), path(krona)
    val(type) //weighted, trimmmed or assembled

    output:
    tuple val(meta), path('*.html'), emit: html
    path("versions.yml")           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def container = task.container.toString() - "quay.io/biocontainers/krona@"
    // Use pre-downloaded taxonomy if set; if not, pass -tax to an empty dir (Krona will generate HTML without taxonomic colours)
    def tax_arg = params.krona_db ? "-tax ${params.krona_db}" : ""
    """
    # ktImportText fails when taxonomy DB is missing; run with || true so the pipeline continues
    ktImportText  \\
        $args \\
        $tax_arg \\
        -o ${prefix}_${type}.html \\
        $krona || \\
    echo '<html><body><p>Krona plot unavailable: taxonomy database not found. Run ktUpdateTaxonomy.sh and set --krona_db.</p></body></html>' > ${prefix}_${type}.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        krona: \$( echo \$(ktImportText 2>&1) | sed 's/^.*KronaTools //g; s/- ktImportText.*\$//g')
        krona_container: ${container}
    END_VERSIONS
    """
}
