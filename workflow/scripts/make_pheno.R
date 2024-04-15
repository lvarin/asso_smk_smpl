library(tidyverse)
# Debug
sample_sheet_file="input_files/samples_phenotypes.tsv"
pheno_columns=c("example_phenotype")
pheno_file="results/pheno_cov/pheno.pheno"

sample_sheet_file=snakemake@input[["sample_sheet_file"]]
pheno_columns=snakemake@params[["pheno_columns"]]
pheno_file=snakemake@output[["pheno_file"]]


sample_sheet<-read_tsv(sample_sheet_file)

pheno=sample_sheet %>%
  select(sample, all_of(pheno_columns))%>%
  mutate(FID=sample, IID=sample)%>%
  select(FID,IID, all_of(pheno_columns))

write_tsv(x=pheno,
          file=pheno_file)
