# PHoeNIx MIXED Mode — Running Local and SRA Reads Together

The `MIXED` mode (and its CDC internal counterpart `CDC_MIXED`) allows you to analyse
local Illumina reads and NCBI SRA reads in a **single pipeline run**, producing one
unified GRiPHin summary across all samples.

---

## Input files

### 1. Local samplesheet (`--input`)

Standard PHoeNIx CSV samplesheet. One row per sample.

```csv
sample,fastq_1,fastq_2
SAMPLE_A,/data/reads/SAMPLE_A_R1.fastq.gz,/data/reads/SAMPLE_A_R2.fastq.gz
SAMPLE_B,/data/reads/SAMPLE_B_R1.fastq.gz,/data/reads/SAMPLE_B_R2.fastq.gz
```

### 2. SRA accession list (`--input_sra`)

Plain text file, one accession per line. Accepts SRR, ERR and DRR accessions.

```
SRR12345678
SRR87654321
ERR1234567
```

---

## Usage scenarios

### Scenario 1 — Local reads only
```bash
nextflow run egeza/phoenix \
  --mode PHOENIX \
  --input samplesheet.csv \
  --kraken2db /path/to/kraken2db \
  --outdir results \
  -profile singularity
```

### Scenario 2 — SRA reads only
```bash
nextflow run egeza/phoenix \
  --mode SRA \
  --input_sra accessions.txt \
  --kraken2db /path/to/kraken2db \
  --outdir results \
  -profile singularity
```

### Scenario 3 — Local + SRA reads (MIXED)
```bash
nextflow run egeza/phoenix \
  --mode MIXED \
  --input samplesheet.csv \
  --input_sra accessions.txt \
  --kraken2db /path/to/kraken2db \
  --outdir results \
  -profile singularity
```

> **What happens internally:**
> 1. SRA accessions are downloaded via `fasterq-dump` and renamed.
> 2. An SRA samplesheet is auto-generated.
> 3. The local samplesheet and the SRA samplesheet are merged into a single
>    `merged_samplesheet.csv`.
> 4. All samples (local + SRA) are processed together through the standard
>    PHoeNIx QC → assembly → AMR → GRiPHin workflow.

### Scenario 4 — Assembled contigs only
```bash
nextflow run egeza/phoenix \
  --mode SCAFFOLDS \
  --input scaffolds_samplesheet.csv \
  --kraken2db /path/to/kraken2db \
  --outdir results \
  -profile singularity
```

---

## CDC internal versions

For internal CDC use (adds BUSCO, SRST2, assembled-scaffold Kraken2):

| Public mode   | CDC internal mode |
|---------------|-------------------|
| `PHOENIX`     | `CDC_PHOENIX`     |
| `SRA`         | `CDC_SRA`         |
| `MIXED`       | `CDC_MIXED`       |
| `SCAFFOLDS`   | `CDC_SCAFFOLDS`   |

```bash
nextflow run egeza/phoenix \
  --mode CDC_MIXED \
  --input samplesheet.csv \
  --input_sra accessions.txt \
  --kraken2db /path/to/kraken2db \
  --outdir results \
  -profile singularity
```

---

## Mode summary table

| Mode               | `--input` | `--input_sra` | Input type                        |
|--------------------|:---------:|:-------------:|-----------------------------------|
| `PHOENIX`          | ✅        | ❌            | Local reads                       |
| `SRA`              | ❌        | ✅            | NCBI SRA reads                    |
| `MIXED`            | ✅ or ❌  | ✅ or ❌      | Local + SRA (at least one required)|
| `SCAFFOLDS`        | ✅        | ❌            | Pre-assembled contigs             |
| `UPDATE_PHOENIX`   | ✅/`--indir` | ❌         | Re-run AMR/MLST on existing output|
| `COMBINE_GRIPHINS` | ✅        | ❌            | Merge GRiPHin summaries           |

---

## Notes

- `MIXED` mode requires at least one of `--input` or `--input_sra`. Passing only
  one still works but a warning will suggest using `PHOENIX` or `SRA` instead.
- All samples — regardless of source — go through identical QC, assembly, AMR and
  MLST steps, and appear together in the final GRiPHin Excel/TSV summary.
- Internet access is required at runtime when `--input_sra` is used (for NCBI download).
