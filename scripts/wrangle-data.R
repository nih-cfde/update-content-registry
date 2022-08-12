library(jsonlite)
library(dplyr)
library(readr)
library(scales)
library(stringr)
library(tidyr)

# glycan alias table wrangling
df <- fromJSON("compound.data.json")

df2 <- df %>%
  mutate(CV_ID = ifelse(is.na(PUBCHEM_CID), GLYTOUCAN_ID, PUBCHEM_CID),
         PUBCHEM_CID = ifelse(is.na(PUBCHEM_CID), "No CID available", PUBCHEM_CID),
         MASS = format(MASS, big.mark = ",", scientific = FALSE),
         MASS = ifelse(is.na(MASS), "Unavailable", paste(MASS, "Da", sep = " "))) %>%
  select(CV_ID, GLYTOUCAN_ID, PUBCHEM_CID, COMPOSITION, 
         MASS, IMAGE_URL, LINK_OUT_URL) %>%
  arrange(CV_ID)


write.table(df2, "compounds_glygen2pubchem.tsv", 
            row.names = F, sep = "\t" , quote = F)

# lincs wrangling
d3 <- read.table("compound_IDs_for_lincs_chemical_sim_appyter.txt") %>%
  arrange(V1)
head(df)

write.table(df3, "compound_IDs_for_lincs_chemical_sim_appyter.txt", 
            row.names = F, sep = "\t" , quote = F, col.names = F)

