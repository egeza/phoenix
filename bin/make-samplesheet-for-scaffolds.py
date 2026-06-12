import os
import csv
import sys

# Directories
assembly_dir = sys.argv[1]  # assemblies dir
output_csv = sys.argv[2]  # samplesheet.csv

# Collect assemblies (supports .fa, .fasta, and .gz variants)
assemblies = {}
for fname in os.listdir(assembly_dir):
    if not fname.endswith((".fa", ".fasta", ".fa.gz", ".fasta.gz")):
        continue
    sample = fname
    if sample.endswith(".gz"):
        sample = os.path.splitext(sample)[0]
    sample = os.path.splitext(sample)[0]
    assemblies[sample] = os.path.join(assembly_dir, fname)

# Write CSV
with open(output_csv, "w", newline="") as out:
    writer = csv.writer(out)
    writer.writerow(["sample", "assembly"])
    for sample in sorted(assemblies.keys()):
        writer.writerow([sample, assemblies[sample]])

print(f"CSV file written: {output_csv}")
