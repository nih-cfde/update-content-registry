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
df3 <- read.table("compound_IDs_for_lincs_chemical_sim_appyter.txt") %>%
  arrange(V1)
head(df3)

write.table(df3, "compound_IDs_for_lincs_chemical_sim_appyter.txt", 
            row.names = F, sep = "\t" , quote = F, col.names = F)

## which compounds have which annotations 
compound <- read_tsv("../validate/compound.tsv") %>%
  mutate(V1 = as.character(id))

DrugCentral <- read.table("compound_IDs_DrugCentral.txt") %>%
  mutate(V1 = as.character(V1),
         DrugCentral = V1)

LINCS <- read.table("compound_IDs_for_lincs_chemical_sim_appyter.txt") %>%
  mutate(V1 = as.character(V1), LINCS = V1)

PubChem <- read.table("compound_IDs_PubChem.txt") %>%
  mutate(V1 = as.character(V1), PubChem = V1)

GlyTouCan <- read.table("compound_IDs_GlyTouCan.txt") %>%
  mutate(V1 = as.character(V1), GlyTouCan = V1)

GlyTouCan %>%
  filter(V1 == "9305")


compounds_with_markdown <- full_join(compound, DrugCentral) %>%
  full_join(., LINCS) %>%
  full_join(., PubChem) %>%
  full_join(., GlyTouCan) %>%
  mutate(DrugCentral = ifelse(is.na(DrugCentral), "___________", "DrugCentral"),
         LINCS = ifelse(is.na(LINCS), "_____", "LINCS"),
         PubChem = ifelse(is.na(PubChem), "_______", "PubChem"),
         GlyTouCan = ifelse(is.na(GlyTouCan), "__________", "GlyTouCan"),
         compounds_with_markdown = paste(DrugCentral, LINCS, PubChem, GlyTouCan, sep = " ")) %>%
  select(id, name, compounds_with_markdown) %>%
  as_tibble() %>%
  distinct()
compounds_with_markdown

count(compounds_with_markdown, compounds_with_markdown) %>%
  arrange(n)


compounds_with_markdown %>%
  filter(compounds_with_markdown != "___________ _____ _______") %>%
  count()

compounds_with_markdown %>%
  filter(compounds_with_markdown == "DrugCentral _____ PubChem GlyTouCan") %>%
  pull(id)


compounds_with_markdown %>%
  filter(compounds_with_markdown %in% c("DrugCentral LINCS PubChem __________",
                          "DrugCentral LINCS _______ __________")) %>%
  pull(id)


