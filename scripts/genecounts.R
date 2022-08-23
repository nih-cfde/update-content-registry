# count number of over lapping gene sets from content registry sprint

library(dplyr)
library(tidyr)
library(readr)

# read gene reference list
ref <- read_tsv("../data/validate/ensembl_genes.tsv") %>%
  select(id)
head(ref)

# download genes in portal. 
# update to get from https://app.nih-cfde.org/ermrest/catalog/registry/attribute/CFDE:gene/id@sort(id)

genes <- read.csv("~/Downloads/Gene (4).csv") %>%
  inner_join(., ref) %>%
  select(id) %>%
  arrange(id)

#write.table(genes, "../data/inputs/STAGING_PORTAL__available_genes__2022-08-19.txt",
#            col.names = F, row.names = F, quote = F)

genes <- read.table("../data/inputs/STAGING_PORTAL__available_genes__2022-08-19.txt") %>%
  mutate(ENSEMBL_ID = V1, 
         aliases = "Aliases")
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

gtexwidget <- read.table("../data/inputs/gene_IDs_for_gtex.txt") %>%
  mutate(gtexwidget = "GTExWidget")

df <- full_join(genes, kg) %>%
  full_join(., lincs) %>%
  full_join(., metgene) %>%
  full_join(., disease) %>%
  full_join(., gtexwidget) %>%
  mutate(lincs = replace_na(lincs, "__________________"),
         kg = replace_na(kg, "______________"),
         disease = replace_na(disease, "________"),
         metgene = replace_na(metgene, "____________"),
         gtexwidget = replace_na(gtexwidget, "__________"),
         markdown = paste(aliases, lincs, kg, metgene, gtexwidget, disease,  sep = " ")) %>%
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
  filter(markdown == "Aliases LincsReverseSearch KnowledgeGraph Metabolomics GTExWidget Diseases") %>%
  pull(ENSEMBL_ID) %>%
  head()

#
l1 <- inner_join(genes, kg) %>% select(ENSEMBL_ID) 
#write.table(l1, "../data/inputs/gene_IDs_for_gene_kg.txt", row.names = F, col.names = F, quote = F)

l2 <- left_join(genes, lincs) %>% select(ENSEMBL_ID) 
#write.table(l2, "../data/inputs/gene_IDs_for_lincs_reverse_search.txt", row.names = F, col.names = F, quote = F)

l3 <- inner_join(genes, lincs2) %>% select(ENSEMBL_ID) 
#write.table(l3, "../data/inputs/gene_IDs_for_lincs_geo_reverse_appyter.txt", row.names = F, col.names = F, quote = F)

