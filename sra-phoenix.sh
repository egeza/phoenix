#!/bin/bash
#SBATCH --job-name='phoenix-pub'
#SBATCH --nodes=1 --ntasks=32
#SBATCH --time=8:00:00
#SBATCH --mem=160g
#SBATCH --output=/cbio/users/ephie/unizululand/publications/phoenix/phoenix-test-stdout.log
#SBATCH --error=/cbio/users/ephie/unizululand/publications/phoenix/phoenix-test-stderr.log
#SBATCH --mail-user=ephie.geza@uct.ac.za


proj="/cbio/users/ephie/unizululand/publications/phoenix/"

#cd  ${proj}phoenix
mkdir -p /tmp/$USER/phx_run

cd /tmp/$USER/phx_run
NXF_HOME=/tmp/$USER/nextflow 

nextflow run /cbio/users/ephie/unizululand/publications/phoenix/main.nf \
  -resume \
  -w '/cbio/users/ephie/unizululand/publications/phoenix/work-phoenix' \
  -profile singularity \
  --mode SRA --use_sra  \
  --input_sra '/cbio/users/ephie/unizululand/publications/phoenix/samplesheet.csv'  \
  --kraken2db '/cbio/users/ephie/tools/phoenix/kraken_db_benlangmead'  \
  --outdir '/cbio/users/ephie/unizululand/publications/phoenix/phoenix_out'

