library(tidyverse)
# Debug
sample_sheet_file="input_files/samples_phenotypes.tsv"
cov_pcs_file="results/covar_PCA/common_vars.eigenvec"
cov_columns=c("age")
covariates_nPC=10
cov_file="results/pheno_cov/pheno.pheno"

sample_sheet_file=snakemake@input[["sample_sheet_file"]]
cov_pcs_file=snakemake@input[["cov_pcs_file"]]
cov_columns=snakemake@params[["cov_columns"]]
covariates_nPC=snakemake@params[["covariates_nPC"]]
cov_file=snakemake@output[["cov_file"]]


sample_sheet<-read_tsv(sample_sheet_file)
cov_pcs<-read.table(file=cov_pcs_file, 
                    col.names = c("FID", "IID", 
                                paste0("PC", 1:covariates_nPC )) )

cov=sample_sheet %>%
  select(sample, all_of(cov_columns))%>%
  mutate(FID=sample, IID=sample)%>%
  left_join(cov_pcs %>% select(-FID), by="IID") %>%
  select(FID,IID, all_of(cov_columns), starts_with("PC") )

write_tsv(x=cov,
          file=cov_file)
