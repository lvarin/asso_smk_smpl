## Snakemake pipeline for conducting GWAS

This is a simple dockerized snakemake pipeline for conducting Genome-Wide Association Studies (GWAS). It assumes that quality controlled genotype files are available.

# Setup / running the pipeline:
1. Go to a directory where you would like to run the analyses and clone this repository:
```
git clone https://github.com/Ax-Sch/asso_smk_smpl.git
cd asso_smk_smpl
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

3. Copy the genotype and phenotype data in the workflow directory (putting them somewhere else is problematic when we use containers). Here is an example - to use your own data, see below. Example data derived from the 1000 genomes project can be found here: https://uni-bonn.sciebo.de/s/4jdQGESb92jCaze

I.e. run the following commands within the directory of the repository and example data will be placed into the folder "input_files":
```
curl -J -O "https://uni-bonn.sciebo.de/s/4jdQGESb92jCaze/download"
unzip input_files.zip
```
The config file (config/config.yaml) is configured to work with these files.


4. Now you can execute the pipeline, here as a dockerized version:
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

# Analyzing your own data:

If you would like to analyze your own data, the following files are needed (see the example data):
- plink fam/bim/bed files of your genotyped and quality controlled SNPs.
- imputed vcf file(s) (e.g. one for each chromosome)
- a tab-separated sample sheet file with sample-ids, phenotypes and covariates which should be included in the analysis. Please have a look at the example file: The file is expected to have a header row, the column "sample" is mandatory; the remaining columns are expected to contain phenotypes and covariates. Principal components of genotype data are not required here, as this is computed as part of the pipeline. 

The files should be placed within the directory of the repository, as directories outside of this folder structure will not be accessible by containers.

Please open the file config/config.yaml and adjust the settings: e.g. adjust the file names; add the names of the columns of the sample sheet file that you would like to use as phenotypes and covariates; set the number of PCs that you would like to include. 

# Acknowledgement:
In particular, I would like to thank the developers of the software that is used within this repository, e.g. snakemake, regenie, plink, plink2, R. tidyverse


