library(tidyr)
library(dplyr)
library(readr)

## MetGene

# get list of genes
# cd ~/Downloads
# curl -O https://raw.githubusercontent.com/nih-cfde/knowledge-base-deposit/main/MW/hsa_mgp_geneid_with_kegg_id_ConvertedGeneIDs.txt

# assumes working dir is scripts dir

df <- read.table("~/Downloads/hsa_mgp_geneid_with_kegg_id_ConvertedGeneIDs (1).txt", header = T) 

df2 <- read.table("../data/inputs/STAGING_PORTAL__available_genes__2022-07-13.txt") %>%
  rename(ENSEMBL = V1) %>%
  inner_join(., df) %>%
  arrange(ENSEMBL) %>%
  dplyr::select(ENSEMBL) 
head(df2)

#write.table(df2, "../data/inputs/gene_IDs_for_MetGene.txt", 
#            row.names = F, col.names = F, quote =  F)

#write.table(head(df2), "../data/inputs/gene_IDs_for_MetGene_test.txt", 
#          row.names = F, col.names = F, quote =  F)

################################

## GTEx 

# curl -0 GTEx_Analysis_2017-06-05_v8_RNASeQCv1.1.9_gene_reads.gct.gz
# gunzip GTEx_Analysis_2017-06-05_v8_RNASeQCv1.1.9_gene_reads.gct.gz
# sed '1,2d' GTEx_Analysis_2017-06-05_v8_RNASeQCv1.1.9_gene_reads.gct | cut -f 1  > GTEx.list.txt

df3 <- read.table("~/Downloads/GTEx.list.txt", header = T) %>%
  arrange(Name) %>%
  separate(Name, into = c("V1", "Transcript"), sep  = "\\.") %>%
  select(V1)
head(df3)

df4 <- read.table("../data/inputs/STAGING_PORTAL__available_genes__2022-07-13.txt") %>%
  inner_join(., df3) %>%
  arrange(V1) %>%
  dplyr::select(V1) 
head(df4)

write.table(df4, "../data/inputs/gene_IDS_for_gtex.txt", 
            row.names = F, col.names = F, quote =  F)
