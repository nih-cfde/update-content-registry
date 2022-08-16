library(tidyr)
library(dplyr)

# get list of genes
# cd ~/Downloads
# curl -O https://raw.githubusercontent.com/nih-cfde/knowledge-base-deposit/main/MW/hsa_mgp_geneid_with_kegg_id_ConvertedGeneIDs.txt

# assumes working dir is scripts dir

df <- read.table("~/Downloads/hsa_mgp_geneid_with_kegg_id_ConvertedGeneIDs (1).txt", header = T) 

df2 <- read.table("../data/inputs/STAGING_PORTAL__available_genes__2022-07-13.txt") %>%
  rename(ENSEMBL = V1) %>%
  inner_join(., df) %>%
  arrange(ENSEMBL) %>%
  select(ENSEMBL) 

head(df2)

write.table(df2, "gene_IDs_for_MetGene.txt", 
            row.names = F, col.names = F, quote =  F)

write.table(head(df2), "gene_IDs_for_MetGene_test.txt", 
            row.names = F, col.names = F, quote =  F)
