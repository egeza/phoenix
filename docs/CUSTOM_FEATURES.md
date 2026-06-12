# PHoeNIx Custom Enhancements

This document describes features added to [egeza/phoenix](https://github.com/egeza/phoenix)
beyond the upstream CDCgov/phoenix v2.3.1 release.

---

## 1. DRR Accession Support

**Modes affected:** `SRA`, `CDC_SRA`, `MIXED`, `CDC_MIXED`

The `--input_sra` accession list now accepts accessions from all three international
SRA repositories:

| Prefix | Repository |
|--------|-----------|
| `SRR`  | NCBI (USA) |
| `ERR`  | ENA (Europe) |
| `DRR`  | DDBJ (Japan) |

**Example accession file:**
```
SRR12345678
ERR1234567
DRR098765
```

---

## 2. QUAST N50 and Longest Contig in Summary

**File:** `bin/Phoenix_summary_line.py`

Two additional assembly quality columns are now included in the per-sample summary
line and the GRiPHin report:

| Column | Description |
|--------|-------------|
| `N50` | N50 contig length from QUAST |
| `Longest_Contig` | Length of the longest contig from QUAST |

These appear after the existing `Contigs` column and before `GC_Percent`.

---

## 3. Abricate Virulence Gene Detection (All Samples)

**File:** `workflows/phoenix.nf`

Abricate is run on **all samples** for virulence gene detection. The database used
depends on the taxonomic classification of the sample:

| Organism | Database used |
|----------|--------------|
| *Escherichia* spp. | `ecoli_vf` |
| All other organisms | `vfdb` |

Results are merged into a single channel and passed to GRiPHin as the
`Virulence_Genes` column.

**Implementation:**
```groovy
// Escherichia → ecoli_vf
ABRICATE_ECOLI_VF(ecoli_vf_scaffolds_ch.map{ meta, scaffolds -> [meta, scaffolds, "ecoli_vf"] })

// All others → vfdb
ABRICATE_VFDB(non_ecoli_scaffolds_ch.map{ meta, scaffolds -> [meta, scaffolds, "vfdb"] })

abricate_vfdb_ch = ABRICATE_ECOLI_VF.out.report.mix(ABRICATE_VFDB.out.report)
```

---

## 4. Abricate PlasmidFinder Detection (All Samples)

**File:** `workflows/phoenix.nf`

Abricate is run on all samples using the `plasmidfinder` database to detect plasmid
replicons. Results appear in the GRiPHin report as the `Plasmid_Abricate` column,
complementing the existing GAMMA-based plasmid marker detection.

```groovy
ABRICATE_PF(BBMAP_REFORMAT.out.filtered_scaffolds
    .map{ meta, scaffolds -> [meta, scaffolds, "plasmidfinder"] })
```

---

## 5. MIXED Mode

**Files:** `main.nf`, `modules/local/merge_samplesheets.nf`

See [MIXED_MODE_USAGE.md](MIXED_MODE_USAGE.md) for full documentation.

---

---

## Tool Version Comparison: phoenix_v1 (v2.2.0) vs phoenix (v2.3.1)

`phoenix_v1` in this workspace is CDCgov/phoenix **v2.2.0**. The current `phoenix` is **v2.3.1** plus the custom enhancements above. The following tools were updated across those upstream releases:

| Tool | v2.2.0 (phoenix_v1) | v2.3.1 (phoenix) |
|------|--------------------|--------------------|
| AMRFinderPlus | v3.12.8 | **v4.2.7** |
| AMRFinder DB | 2024-01-31.1 | **2026-03-24.1** |
| SPAdes | v3.15.5 | **v4.2.0** |
| BUSCO | v5.4.7 | **v6.0.0** |
| QUAST | v5.0.2 | **v5.3.0** |
| BBTools | v39.01 | **v39.13** |
| MLST (tseemann) | v2.23.0 (2023-07-28) | **v2.25.0 (2025-12-31)** |
| MLST DB | 20231228 | **20260603** |
| SRA-tools | v3.1.1 | **v3.2.0** |
| Entrez-direct | v16.2 | **v24.0** |
| MultiQC | v1.14 | **v1.24.1** |
| ANI REFSEQ DB | 20241028 | **20260521** |
| names/nodes DB | — | **20260430** |

Tools with **unchanged** containers between v2.2.0 and v2.3.1: Abricate, Bakta, BBDuk, CheckM2, FastANI, FastP, FastQC, GAMMA, Kaptive, Kleborate, Kraken2, Krona, Mash, Prokka, SRST2, Shigapass, SerotypeFinder.

> Full upstream changelogs: [v2.2.0](https://github.com/CDCgov/phoenix/releases/tag/v2.2.0) | [v2.2.1](https://github.com/CDCgov/phoenix/releases/tag/v2.2.1) | [v2.3.0](https://github.com/CDCgov/phoenix/releases/tag/v2.3.0) | [v2.3.1](https://github.com/CDCgov/phoenix/releases/tag/v2.3.1)

---

## GRiPHin Summary Column Reference

Columns added or modified by these enhancements (relative to upstream v2.3.1):

| Column | Source | Notes |
|--------|--------|-------|
| `N50` | QUAST | New |
| `Longest_Contig` | QUAST | New |
| `Virulence_Genes` | Abricate (ecoli_vf / vfdb) | New; all samples |
| `Plasmid_Abricate` | Abricate (plasmidfinder) | New; all samples |
