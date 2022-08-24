library(tidyr)
library(dplyr)

# get list of genes
# cd ~/Downloads
# curl -O https://raw.githubusercontent.com/nih-cfde/knowledge-base-deposit/main/MW/hsa_mgp_geneid_with_kegg_id_ConvertedGeneIDs.txt
# curl -O https://storage.googleapis.com/gtex_analysis_v9/long_read_data/LORALS_GTEx_v9_ase_quant_results.gencode.txt.gz 
# gunzip LORALS_GTEx_v9_ase_quant_results.gencode.txt.gz 

# assumes working dir is scripts dir

df <- read.table("~/Downloads/hsa_mgp_geneid_with_kegg_id_ConvertedGeneIDs (1).txt", header = T) 

df2 <- read.table("../data/inputs/STAGING_PORTAL__available_genes__2022-07-13.txt") %>%
  rename(ENSEMBL = V1) %>%
  inner_join(., df) %>%
  arrange(ENSEMBL) %>%
  dplyr::select(ENSEMBL) 

head(df2)

write.table(df2, "../data/inputs/gene_IDs_for_MetGene.txt", 
            row.names = F, col.names = F, quote =  F)

#write.table(head(df2), "../data/inputs/gene_IDs_for_MetGene_test.txt", 
  #          row.names = F, col.names = F, quote =  F)


df3 <- read.table("~/Downloads/LORALS_GTEx_v9_ase_quant_results.gencode.txt", 
                  header = T) %>%
  separate(Gene, into = c("ENSEMBL", "Transcript"), sep = "\\.") %>%
  dplyr::select(ENSEMBL)  %>%
  arrange(ENSEMBL) %>%
  inner_join(., df2)
head(df3)

write.table(df3, "../data/inputs/gene_IDs_for_gtex.txt", 
            row.names = F, col.names = F, quote =  F)
