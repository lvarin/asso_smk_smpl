library(qqman)
library(data.table)
library(R.utils)

# initially based on a script from the COVID-HGI; highly modified

# debug
in_file="results/regenie_association_merged/example_phenotype.regenie.gz"
bp_col="GENPOS"
chr_col="CHROM"
pcols =c("LOG10P")
output_prefix=""

in_file=snakemake@input[["merged_assoc"]]
bp_col=snakemake@params[["bp_col"]]
chr_col=snakemake@params[["chr_col"]]
pcols=snakemake@params[["pcols"]]
output_prefix=snakemake@params[["output_prefix"]]

data <- fread(in_file, header=T)

options(bitmapType='cairo')

print(summary(data))
print( summary( data[[chr_col]] ) )
#colnames(data) <- toupper( colnames(data) )

print(summary(as.factor(data[[chr_col]])))

data[[chr_col]] <- gsub("chr","",data[[chr_col]])
data[[chr_col]] <- gsub("X|chrX","23",data[[chr_col]])
data[[chr_col]] <- gsub("Y|chrY","24",data[[chr_col]])
data[[chr_col]] <- gsub("MT|chrMT|M|chrM","25",data[[chr_col]])

data[[chr_col]] <- as.numeric(data[[chr_col]])
data <- data[ !is.na(data[[chr_col]]) ]

quants <- c(0.7,0.5,0.456,0.1,0.01, 0.001)



for( pcol in pcols) {
  data[[pcol]]<- 10^(-data[[pcol]])
  subdata <- data[ !is.na(data[[pcol]]) & is.numeric( data[[pcol]]  ) ]
  
  lambda  <- round(  quantile(  (qchisq(1-subdata[[pcol]], 1) ), probs=quants ) / qchisq(quants,1), 3)
  png( paste(output_prefix,"_", pcol ,"_qqplot.png", sep="" ))
  qq(subdata[[pcol]], main=paste("\nlambda ", quants, ": ", lambda, sep="" ) )
  dev.off()
  sink( paste(output_prefix,"_",  pcol ,"_qquantiles.txt", sep="" ) )
  cat( paste( quants, ":", lambda, sep=""))
  sink()
  
  print("subsetting p-vals < 0.01 for manhattan...")
  
  subdata <- subdata[ subdata[[pcol]]<0.01 & subdata[[pcol]]>0 ]
  print( paste0("Plotting manhattan with ", nrow(subdata), " variants") )
  print( summary(subdata[[pcol]] ))
  png( paste(output_prefix,"_",pcol,"_manhattan.png", sep=""), width=1000, height=400)
  logs <- -log10(subdata[[pcol]])
  
  manhattan( subdata , chr=chr_col, bp=bp_col, p=pcol,snp="ID", ylim=c( 2,max(logs)+1)  )
  dev.off()
  
}


