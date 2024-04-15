## Snakemake pipeline for conducting GWAS

This is a simple dockerized snakemake pipeline for conducting Genome-Wide Association Studies (GWAS). It assumes that quality controlled genotype files are available.

Setup:
1. Go to a directory where you would like to run the analyses and clone this repository:
```
git clone XXX
cd 
```

2. Install snakemake version 7 with singularity:
I recommend installing snakemake via conda. If you do not have conda running, e.g. download miniconda3 (https://docs.conda.io/en/latest/miniconda.html) by running the following commands on a linux system:
```
### run only when you do not have conda installed:
curl -sL "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" > "Miniconda3.sh"
bash Miniconda3.sh
rm Miniconda3.sh
```
Then install snakemake/singularity via conda:
```
conda env create -f workflow/envs/snakemake7.yaml
```

3. Copy the genotype and phenotype data in the workflow directory (putting them somewhere else is problematic when we use containers).
Example data derived from the 1000 genomes project can be found here: https://uni-bonn.sciebo.de/s/4jdQGESb92jCaze
I.e. run the following commands within the directory of the repository and example data will be placed into the folder "input_files":
```
curl -J -O "https://uni-bonn.sciebo.de/s/4jdQGESb92jCaze/download"
unzip input_files.zip
```
If you would like to analyze your own data, the following files are needed (see the example data):
- plink1 fam/bim/bed files of your genotyped SNPs.
- imputed vcf files (e.g. one for each chromosome)
- a sample sheet tsv file with your phenotypes and the covariates that should be included in the analysis.

Then adjust the file config/config.yaml to point to these files; also add the phenotype and covariate column names that you would like to use. 

4. Now you can execute the pipeline, here in a dockerized version:
```
conda activate snakemake7 # activates the snakemake7 conda environment
snakemake -np # do a dry run first
snakemake --cores 1 --use-singularity --use-conda # this runs the dockerized version of the pipeline
```

If you would like to run the pipeline without containers (better for development), slightly modify the commands above:
```
conda activate snakemake7
snakemake -np # do a dry run first
snakemake --cores 1 --use-conda
```


