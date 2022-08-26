library(readr)
library(tidyr)
library(dplyr)
dc <- read_table("../data/inputs/compound_IDs_DrugCentral.txt", 
                 col_names = F, col_types = cols(X1 = col_character())) %>%
  mutate(dc = "DrugCentral")

kg <- read_table("../data/inputs/compound_IDs_for_gene_kg.txt",  
                 col_names = F, col_types = cols(X1 = col_character())) %>%
  mutate(kg = "KnowledgeGraph")

lincs <- read_table("../data/inputs/compound_IDs_for_lincs_chemical_sim_appyter.txt",  
                    col_names = F, col_types = cols(X1 = col_character())) %>%
  mutate(lincs = "LINCS")

gly <- read_table("../data/inputs/compound_IDs_GlyTouCan.txt",
                  col_names = F, col_types = cols(X1 = col_character())) %>%
  mutate(gly = "GlyTouCan")

pc <- read_table("../data/inputs/compound_IDs_PubChem.txt", 
                 col_names = F, col_types = cols(X1 = col_character())) %>%
  mutate(pc = "PubChem")


df <- full_join(gly, kg) %>%
  full_join(., lincs) %>%
  full_join(., dc) %>%
  full_join(., pc) %>%
  mutate(gly = replace_na(gly, "_________"),
         kg = replace_na(kg, "______________"),
         lincs = replace_na(lincs, "_____"),
         dc = replace_na(dc, "___________"),
         pc = replace_na(pc, "_______"),
         markdown = paste(gly, kg, lincs, dc, pc,  sep = " ")) %>%
  select(X1, markdown) %>%
  rename("id" = X1) %>%
  arrange(id) %>%
  as_tibble() %>%
  distinct() %>%
  drop_na()
head(df)
tail(df)

count(df, markdown) %>%
  arrange(n) %>%
  as.data.frame()

length(df$id)


df %>%
  filter(markdown == "GlyTouCan ______________ _____ DrugCentral PubChem") %>%
  pull(id) %>%
  head()
