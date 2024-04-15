## Snakemake pipeline for conducting association analysis

This is a simple dockerized snakemake pipeline for conducting Genome-Wide Association Studies (GWAS). It assumes that quality controlled genotype files are available.
It can either 


### Modes or running - in container, containerized, conda:
This pipeline can run in at least 3 modes:

A) This workflow can either run entirely in a docker container, 
e.g. use https://hub.docker.com/r/condaforge/mambaforge :
```
docker pull condaforge/mambaforge
docker run -i -t -v "$(pwd)":/local_folder_in_cnt condaforge/mambaforge bash
cd local_folder_in_cnt
```
Then run the commands below, but skip step 2. 


B) Alternatively, snakemake can be installed locally and the rules can be run within containers (dockerized version).
 
C) The pipeline can be run using conda and no containerization.

For execution on a HPC modes B and C are probably best.


### Setting up and running the pipeline:
To run the pipeline the following steps are necessary:
1. Go to a directory where you would like to run the analyses and clone this repository:
```
git clone https://github.com/Ax-Sch/asso_smk_smpl.git
cd asso_smk_smpl
```

2. Skip if conda is present or you are in mode A: Install conda, e.g. download miniconda3 (https://docs.conda.io/en/latest/miniconda.html) by running the following commands on a linux system:
```
### run only when you do not have conda installed:
curl -sL "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" > "Miniconda3.sh"
bash Miniconda3.sh
rm Miniconda3.sh
```

3. Install snakemake version 7 with singularity via conda:
```
conda env create -f workflow/envs/snakemake7.yaml
```

4. Copy the genotype and phenotype data in the workflow directory (putting them somewhere else is problematic when we use containers). Here is an example - to use your own data, see below. Example data derived from the 1000 genomes project can be found here: https://uni-bonn.sciebo.de/s/4jdQGESb92jCaze

I.e. run the following commands within the directory of the repository and example data will be placed into the folder "input_files":
```
conda activate snakemake7
curl -J -O "https://uni-bonn.sciebo.de/s/4jdQGESb92jCaze/download"
unzip input_files.zip
```
The config file (config/config.yaml) is configured to work with these files out of the box.

5. Run the pipeline:
For modes A and C from above or for development, run:
```
conda activate snakemake7
snakemake -np # do a dry run first
snakemake --cores 1 --use-conda
```
For mode B from above, run:
```
conda activate snakemake7 # activates the snakemake7 conda environment
snakemake -np # do a dry run first
snakemake --cores 1 --use-singularity --use-conda # this runs the dockerized version of the pipeline
```


### Analyzing own/real data:

If you would like to analyze your own data, the following files are needed (see the example data):
- plink fam/bim/bed files of your genotyped and quality controlled SNPs.
- imputed vcf file(s) (e.g. one for each chromosome)
- a tab-separated sample sheet file with sample-ids, phenotypes and covariates which should be included in the analysis. Please have a look at the example file: The file is expected to have a header row, the column "sample" is mandatory; the remaining columns are expected to contain phenotypes and covariates. Principal components of genotype data are not required here, as this is computed as part of the pipeline. 

The files should be placed within the directory of the repository, as directories outside of this folder structure will not be accessible by containers.

Please open the file config/config.yaml and adjust the settings: e.g. adjust the file names; add the names of the columns of the sample sheet file that you would like to use as phenotypes and covariates; set the number of PCs that you would like to include. 


### Creating a container with all environments after changes (for mode B)

The pipeline can be containerized after conda environments have been changed. The following commands have to be executed:
```
conda activate snakemake7
snakemake --containerize > dockerfile
docker build -t gwas_pipeline .
docker tag gwas_pipeline axschmidt/gwas_pipeline:0.1
docker push axschmidt/gwas_pipeline:0.1
```


### Acknowledgement:
In particular, I would like to thank the developers of the software that is used within this repository, among others snakemake, regenie, plink, plink2, R, tidyverse.


