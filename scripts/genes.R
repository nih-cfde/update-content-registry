library(tidyr)
library(dplyr)
library(readr)

## MetGene

# get list of genes
# cd ~/Downloads
# curl -O https://raw.githubusercontent.com/nih-cfde/knowledge-base-deposit/main/MW/hsa_mgp_geneid_with_kegg_id_ConvertedGeneIDs.txt

# assumes working dir is scripts dir

df <- read.table("~/Downloads/hsa_mgp_geneid_with_kegg_id_ConvertedGeneIDs (1).txt", header = T) %>%
  arrange(ENSEMBL) %>%
  select(ENSEMBL) 
head(df)

write.table(df, "../data/inputs/gene_IDs_for_MetGene.txt", 
            row.names = F, col.names = F, quote =  F)

#write.table(head(df), "../data/inputs/gene_IDs_for_MetGene_test.txt", 
#          row.names = F, col.names = F, quote =  F)

################################

## GTEx 

# curl -0 GTEx_Analysis_2017-06-05_v8_RNASeQCv1.1.9_gene_reads.gct.gz
# gunzip GTEx_Analysis_2017-06-05_v8_RNASeQCv1.1.9_gene_reads.gct.gz
# sed '1,2d' GTEx_Analysis_2017-06-05_v8_RNASeQCv1.1.9_gene_reads.gct | cut -f 1  > GTEx.list.txt

df2 <- read.table("~/Downloads/GTEx.list.txt", header = T) %>%
  arrange(Name) %>%
  separate(Name, into = c("V1", "Transcript"), sep  = "\\.") %>%
  select(V1) %>%
  distinct(V1) %>%
  filter(grepl("ENSG", V1))

write.table(df2, "../data/inputs/gene_IDS_for_gtex.txt", 
            row.names = F, col.names = F, quote =  F)
