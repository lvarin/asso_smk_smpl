configfile: "config/config.yaml"

containerized: "docker://axschmidt/gwas_pipeline:0.1"

rule all:
	input:
		expand("results/regenie_association_merged/{phenotypes}.regenie.gz", phenotypes=config["phenotype"]["phenotype_columns"] ),
		expand("results/regenie_association_merged_QC/{phenotypes}_LOG10P_manhattan.png", phenotypes=config["phenotype"]["phenotype_columns"] ),


##### >>> file preparation #####

rule prune_common:
	input:
		fam=config["genotype"]["genotype_plink_prefix"] + ".fam",
		bim=config["genotype"]["genotype_plink_prefix"] + ".bim",
		bed=config["genotype"]["genotype_plink_prefix"] + ".bed",
	output:
		pruned_variant_set="results/prune_common/prune_common.prune.in",
	resources: cpus=1, mem_mb=18000, time_job=720, partition=config["medium_part"],
	params:		
		out_prefix=lambda wildcards, output: output["pruned_variant_set"][:-9],
	conda: "envs/plink.yaml"
	shell:
		"""
		plink \
		--bed {input.bed} \
		--bim {input.bim} \
		--fam {input.fam} \
		--chr 1-22 \
		--indep-pairwise 1000 50 0.2 \
		--keep-allele-order \
		--maf 0.01 \
		--out "{params.out_prefix}"
		"""


rule PCA_for_cov:
	input:
		fam=config["genotype"]["genotype_plink_prefix"] + ".fam",
		bim=config["genotype"]["genotype_plink_prefix"] + ".bim",
		bed=config["genotype"]["genotype_plink_prefix"] + ".bed",
		pruned_variant_set="results/prune_common/prune_common.prune.in",
	output:
		eigenv="results/covar_PCA/common_vars.eigenvec"
	resources: cpus=1, mem_mb=18000, time_job=720, partition=config["medium_part"],
	params:		
		out_prefix=lambda wildcards, output: output["eigenv"][:-9],
		covariates_nPC=config["phenotype"]["covariates_nPC"],
	conda: "envs/plink.yaml"
	shell:
		"""
		plink \
		--bed {input.bed} \
		--bim {input.bim} \
		--fam {input.fam} \
		--extract {input.pruned_variant_set} \
		--pca {params.covariates_nPC} \
		--out "{params.out_prefix}"
		"""


rule make_regenie_pheno:
	input:
		sample_sheet_file=config["phenotype"]["sample_sheet"],
	output:
		pheno_file="results/pheno_cov/pheno.pheno",
	params: 
		pheno_columns=config["phenotype"]["phenotype_columns"],
	conda: "envs/R_tidyverse.yaml"
	resources: cpus=1, mem_mb=5000, time_job=720, partition=config["medium_part"],
	script: "scripts/make_pheno.R"


rule make_regenie_cov:
	input:
		sample_sheet_file=config["phenotype"]["sample_sheet"],
		cov_pcs_file="results/covar_PCA/common_vars.eigenvec",
	output:
		cov_file="results/pheno_cov/cov.cov",
	params: 
		cov_columns=config["phenotype"]["covariate_columns"],
		covariates_nPC=config["phenotype"]["covariates_nPC"],
	conda: "envs/R_tidyverse.yaml"
	resources: cpus=1, mem_mb=5000, time_job=720, partition=config["medium_part"],
	script: "scripts/make_cov.R"


rule convert_imputed_vcf:
	input:
		imputed_vcf=config["genotype"]["imp_prefix"] + "{contig}" + config["genotype"]["imp_postfix"],
	output:
		pgen="results/imp_converted/chr{contig}.pgen",
		psam="results/imp_converted/chr{contig}.psam",
		pvar="results/imp_converted/chr{contig}.pvar",
	params:
		plink_out=lambda wildcards, output: output["pgen"][:-5],
		dosage_param=config["genotype"]["dosage_param"]
	conda: "envs/plink2.yaml"
	shell:
		"""
		plink2 \
		--vcf {input.imputed_vcf} dosage={params.dosage_param} \
		--double-id \
		--make-pgen \
		--threads 7 \
		--out {params.plink_out}
		"""

##### <<< file preparation #####





##### >>> association analysis #####

rule regenie_association:
	input:
		cov="results/pheno_cov/cov.cov",
		pheno="results/pheno_cov/pheno.pheno",
		pvar="results/imp_converted/chr{contig}.pvar",
		psam="results/imp_converted/chr{contig}.psam",
		step2_pgen="results/imp_converted/chr{contig}.pgen",
	output:
		step2_NQ2=expand("results/regenie_association/{contig}_{phenotypes}.regenie.gz", 
			phenotypes=config["phenotype"]["phenotype_columns"],
			allow_missing=True)
	params:
		out_prefix="results/regenie_association/{contig}",
		plink_in=lambda wildcards, input: input["step2_pgen"][:-5],
		phenotypes=config["phenotype"]["phenotype_columns"],
	conda: "envs/regenie.yaml"
	shell:
		"""
		mkdir -p results/regenie_association/
                regenie \
		--step 2 \
		--pgen {params.plink_in} \
		--phenoFile {input.pheno} \
		--covarFile {input.cov} \
		--bt \
		--write-samples \
		--gz \
		--ignore-pred \
		--bsize 1000 \
		--minMAC 10 \
		--out {params.out_prefix} && \
		mv {params.out_prefix}_{params.phenotypes}.regenie.gz {output}
		"""
		
		
rule merge_regenie_results:
	input:
		expand("results/regenie_association/{contig}_{phenotypes}.regenie.gz", contig=config["genotype"]["imp_contigs"], allow_missing=True),
	output:
		merged_assoc="results/regenie_association_merged/{phenotypes}.regenie.gz",
	params:
		header="results/regenie_association_merged/header_{phenotypes}.txt"
	conda: "envs/tabix.yaml"
	shell:
		"""
                mkdir -p results/regenie_association_merged/
		if zcat {input} | head -n1 > {params.header}
		then
		echo "error"
		fi
		zcat {input} | grep -v "CHROM" | \
		cat {params.header} - | \
		bgzip > {output}
		"""

##### <<< association analysis #####





##### >>> QC of association results #####

rule generate_qq_plots:
	input:
		merged_assoc="results/regenie_association_merged/{phenotypes}.regenie.gz",
	output:
		out="results/regenie_association_merged_QC/{phenotypes}_LOG10P_manhattan.png"
	resources: cpus=1, mem_mb=30000, time_job=720
	params:
		output_prefix=lambda wildcards, output: output["out"][:-21],
		bp_col="GENPOS",
		chr_col="CHROM",
		pcols="LOG10P",
	conda: "envs/R_qqplot.yaml"
	script: "scripts/qqplot.R"
##### <<< QC of association results #####
