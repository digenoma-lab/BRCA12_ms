######
## Rscript to create a heatmap of results - BRCA nextflow pipeline
## Evelin Gonzalez - 2024
## input: directory whith annotation of annovar to streka (single and pool) and DeepVariant (single and pool)
## output: heatmap of BRCA1 and BRCA2 muations
######

library(maftools)
library(dplyr)
library(tidyr)
#library(tidyverse)

setwd("/mnt/beegfs/home/efeliu/work2024/080524_nextflow_BRCA/HRR_RunBRCA/plots_paper/BRCA12_ms")
### PROCESAMIENTO STRELKA SINGLE
filenames.s <- Sys.glob("../../annovar/*.SS.*hg38_multianno.txt")
annovar_mafs.s = lapply(filenames.s, annovarToMaf,refBuild = "hg38") #convert to MAFs using annovarToMaf
annovar.s = data.table::rbindlist(l = annovar_mafs.s, fill = TRUE) #Merge into single MAF
strelka.single.pass<-annovar.s[annovar.s$Otherinfo10=="PASS" & annovar.s$Func.refGene=="exonic",]
write.table(strelka.single.pass,file="input/Strelka_single_variants_PASS_exonic.tsv",row.names = FALSE, sep = "\t")

### PROCESAMIENTO STRELKA POOL
columns.strelka<-read.csv("../../annovar/samples.strelka.pool.txt",sep = "\t", header = FALSE)
samples<-columns.strelka[10:dim(columns.strelka)[2]]
strelka.s<-unlist(samples[1,], use.names = FALSE)
maf.strelka.pool<-annovarToMaf("../../annovar/Strelka.SP.annovar_annot.hg38_multianno.txt",refBuild = "hg38")
colnames(maf.strelka.pool)[186:268] <-strelka.s

maf.strelka.pool$Tumor_Sample_Barcode<-NULL
maf.strelka.pool_transposed <- maf.strelka.pool %>%
  pivot_longer(cols = all_of(strelka.s), names_to = "Tumor_Sample_Barcode", values_to = "Column_Info")

maf.strelka.pool_transposed_filtered <- maf.strelka.pool_transposed %>%
  filter(!(startsWith(Column_Info, "0/0") | startsWith(Column_Info, ".:."))) %>%
  separate(Column_Info, into = c("GT", "GQ", "GQX", "DP", "DPF", "AD", "ADF", "ADR", "SB", "FT", "PL"), sep = ":")

strelka.pool.pass<-maf.strelka.pool_transposed_filtered[maf.strelka.pool_transposed_filtered$Otherinfo10=="PASS" & maf.strelka.pool_transposed_filtered$Func.refGene=="exonic",]
write.table(strelka.pool.pass,file="input/Strelka_pool_variants_PASS_exonic.tsv",row.names = FALSE, sep = "\t")

### PROCESAMIENTO DEEPVARIANT SINGLE
filenames.d <- Sys.glob("../../annovar/*.DS.*hg38_multianno.txt")
annovar_mafs.d = lapply(filenames.d, annovarToMaf,refBuild = "hg38") #convert to MAFs using annovarToMaf
annovar.d = data.table::rbindlist(l = annovar_mafs.d, fill = TRUE) #Merge into single MAF
deepvariant.single.pass<-annovar.d[annovar.d$Otherinfo10=="PASS" & annovar.d$Func.refGene=="exonic",]
write.table(deepvariant.single.pass,file="input/DeepVariant_single_variants_PASS_exonic.tsv",row.names = FALSE, sep = "\t")

#### PROCESAMIENTO DEEPVARIANT POOL
maf.deepvariant.pool<-annovarToMaf("../../annovar/DeepVariant.DP.annovar_annot.hg38_multianno.txt", table = "ensGene",ens2hugo = FALSE,refBuild = "hg38")
columns.deep<-read.csv("../../annovar/samples.deepvariant.pool.txt",sep = "\t", header = FALSE)
samples<-columns.deep[10:dim(columns.deep)[2]]
deep.s<-unlist(samples[1,], use.names = FALSE)

colnames(maf.deepvariant.pool)[186:268] <- deep.s
maf.deepvariant.pool$Tumor_Sample_Barcode<-NULL
maf.deepvariant.pool_transposed <- maf.deepvariant.pool %>%
  pivot_longer(cols = all_of(deep.s), names_to = "Tumor_Sample_Barcode", values_to = "Column_Info")

maf.deepvariant.pool_transposed_filtered <- maf.deepvariant.pool_transposed %>%
  filter(!(startsWith(Column_Info, "0/0") | startsWith(Column_Info, "./."))) %>%
  separate(Column_Info, into = c("GT","DP","AD","GQ","PL","RNC"), sep = ":")

deepvariant.pool.pass<-maf.deepvariant.pool_transposed_filtered[maf.deepvariant.pool_transposed_filtered$Func.refGene=="exonic",]
write.table(deepvariant.pool.pass,file="input/DeepVariant_pool_variants_PASS_exonic.tsv",row.names = FALSE, sep = "\t")

