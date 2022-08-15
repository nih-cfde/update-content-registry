library(readr)
library(tidyr)
library(dplyr)
library(jsonlite)
library(purrr)

# visit https://app-staging.nih-cfde.org/chaise/recordset/#1/CFDE:protein@sort(nid)
# download the csv file of all the records in the portal

df <- read_csv("~/Downloads/Protein.csv") %>%
  arrange(id) %>%
  mutate(synonyms = NA) %>%
  distinct() %>%
  separate(name, into = c("name", "species"), sep = "_", remove = TRUE) %>%
  select(id, name, description, synonyms, ncbi_taxonomy.name) 
    
head(df)

## get the glygen protein data from github

# $ cd ~/Downloads/
# $ curl -O https://raw.githubusercontent.com/nih-cfde/knowledge-base-deposit/main/GlyGen/protein.data.json

df2 <- fromJSON("~/Downloads/protein.data.json") 
df3 <- df2 %>%
  as_tibble() %>%
  arrange(UNIPROT_AC) %>%
  select(UNIPROT_AC, everything()) %>%
  rename(id = UNIPROT_AC) %>%
  left_join(df, ., by = "id") %>%
  select( -LINK_OUT_URL, -disease) 
names(df3)

write.table(df3, "../data/validate/protein.tsv", 
            row.names = F, quote = F, sep = "\t")

proteinids <- df3 %>% pull(id)

write.table(proteinids, "../data/inputs/protein_IDs.txt", 
            row.names = F, col.names = F, quote = F, sep = "\t")
write.table(head(proteinids), "../data/inputs/proteins_IDs_test.txt", 
            row.names = F, col.names = F, quote = F, sep = "\t")

# make table with proteins, genes, and diesease ids

df4 <- df2 %>%
  as_tibble() %>%
  arrange(UNIPROT_AC) %>%
  select(UNIPROT_AC, everything()) %>%
  rename(id = UNIPROT_AC) %>%
  left_join(df, ., by = "id") %>%
  select( -LINK_OUT_URL) %>%
  filter(disease != "NULL") %>%
  unnest(disease) %>%
  group_by(id, name, ENSEMBL_ID, GENE_NAME, DO_ID) %>%
  summarise(DO_ID = toString(DO_ID)) %>%
  mutate(DO_IDs = paste0(DO_ID, collapse = "|"))  %>%
  select(-DO_ID) %>%
  distinct() %>%
  rename(UNIPROT_AC = id)
head(df4)

write.table(df4, "../data/inputs/proteins2disease2genes.txt", 
            row.names = F, quote = F, sep = "\t")

proteinswithdisease <- pull(df4, UNIPROT_AC )
head(proteinswithdisease)

write.table(proteinswithdisease, "../data/inputs/proteins_IDs_withdisease.txt", 
            row.names = F, quote = F, sep = "\t", col.names = F)


