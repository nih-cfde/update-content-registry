library(jsonlite)
library(dplyr)
library(readr)
library(scales)
library(stringr)
library(tidyr)

# assumes working directory is data/inputs

# glycan alias table wrangling
glycanjson <- fromJSON("compound.data.json")

glycans <- glycanjson %>%
  mutate(CV_ID = ifelse(is.na(PUBCHEM_CID), GLYTOUCAN_ID, PUBCHEM_CID),
         PUBCHEM_CID = ifelse(is.na(PUBCHEM_CID), "No CID available", PUBCHEM_CID),
         MASS = format(MASS, big.mark = ",", scientific = FALSE),
         MASS = ifelse(MASS < 0.01, "NA", paste(MASS, "Da", sep = " "))) %>%
  select(CV_ID, GLYTOUCAN_ID, PUBCHEM_CID, COMPOSITION, 
         MASS, IMAGE_URL, LINK_OUT_URL) %>%
  arrange(CV_ID)
head(glycans)

write.table(glycans, "compounds_glygen2pubchem.tsv", 
            row.names = F, sep = "\t" , quote = F)

glycanids <- glycans %>%
  select(CV_ID)

write.table(glycanids, "compound_IDs_GlyTouCan.txt", 
            row.names = F, col.names = F, sep = "\t" , quote = F)



# lincs wrangling
lincs <- read.table("compound_IDs_for_lincs_chemical_sim_appyter.txt") %>%
  arrange(V1)
head(lincs)

write.table(lincs, "compound_IDs_for_lincs_chemical_sim_appyter.txt", 
            row.names = F, sep = "\t" , quote = F, col.names = F)


## calculate overlapping lists

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
