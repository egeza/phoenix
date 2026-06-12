/*
========================================================================================
    MERGE_SAMPLESHEETS - Combines a local samplesheet with an SRA-generated samplesheet
    into a single CSV for use with PHOENIX_EXTERNAL / PHOENIX_EXQC.
    Used exclusively by the MIXED and CDC_MIXED workflows.
========================================================================================
*/

process MERGE_SAMPLESHEETS {
    label 'process_single'
    tag "merging local + SRA samplesheets"

    input:
    path(local_sheet)   // local samplesheet CSV (--input)
    path(sra_sheet)     // SRA samplesheet CSV from SRA_PREP

    output:
    path('merged_samplesheet.csv'), emit: csv

    script:
    """
    # Write header from local samplesheet
    head -1 ${local_sheet} > merged_samplesheet.csv

    # Append data rows from local samplesheet (skip header)
    tail -n +2 ${local_sheet} >> merged_samplesheet.csv

    # Append data rows from SRA samplesheet (skip header - assumed same format)
    tail -n +2 ${sra_sheet} >> merged_samplesheet.csv
    """
}
