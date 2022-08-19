# count number of over lapping gene sets from content registry sprint

library(dplyr)
library(tidyr)

genes <- read.table("../data/inputs/STAGING_PORTAL__available_genes__2022-07-13.txt") %>%
  mutate(ENSEMBL_ID = V1)
kg <- read.table("../data/inputs/gene_IDs_for_gene_kg.txt") %>%
  mutate(kg = "KnowledgeGraph")
lincs <- read.table("../data/inputs/gene_IDs_for_lincs_reverse_search.txt") %>%
  mutate(lincs = "LincsReverseSearch")

lincs2 <- read.table("../data/inputs/gene_IDs_for_lincs_geo_reverse_appyter.txt") %>%
  mutate(lincs = "LincsReverseSearch")

metgene <- read.table("../data/inputs/gene_IDs_for_MetGene.txt") %>%
  mutate(metgene = "Metabolomics")
disease <- read.table("../data/inputs/gene_IDs_withdisease.txt") %>%
  mutate(disease = "Diseases")

df <- full_join(genes, kg) %>%
  full_join(., lincs) %>%
  full_join(., metgene) %>%
  full_join(., disease) %>%
  mutate(lincs = replace_na(lincs, "__________________"),
         kg = replace_na(kg, "______________"),
         disease = replace_na(disease, "________"),
         metgene = replace_na(metgene, "____________"),
         markdown = paste(lincs, kg, disease, metgene,  sep = " ")) %>%
  select(ENSEMBL_ID, markdown) %>%
  as_tibble() %>%
  distinct() %>%
  drop_na()
head(df)
tail(df)

count(df, markdown) %>%
  arrange(n)

length(df$ENSEMBL_ID)

df %>%
  filter(markdown == "LincsReverseSearch KnowledgeGraph Diseases Metabolomics") %>%
  pull(ENSEMBL_ID)

df %>%
  filter(markdown != "__________________ ______________ ________ ____________") %>%
  count()


df <- inner_join(genes, kg) %>% select(ENSEMBL_ID) 
write.table(df, "../data/inputs/gene_IDs_for_gene_kg.txt", row.names = F, col.names = F, quote = F)

df <- left_join(genes, lincs) %>% select(ENSEMBL_ID) 
write.table(df, "../data/inputs/gene_IDs_for_lincs_reverse_search.txt", row.names = F, col.names = F, quote = F)

df <- inner_join(genes, lincs2) %>% select(ENSEMBL_ID) 
write.table(df, "../data/inputs/gene_IDs_for_lincs_geo_reverse_appyter.txt", row.names = F, col.names = F, quote = F)
