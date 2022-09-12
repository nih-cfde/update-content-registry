library(tidyverse)
library(scales)

df <- read.csv("skipped.csv", header = F)  %>%
  mutate(widget = paste(V2, V1, sep = "\n"))
head(df)

ggplot(df, aes(x = widget, fill = V2)) +
  geom_bar() +
  scale_y_log10() +
  coord_flip() +
  facet_wrap(~V4) +
  labs(subtitle = "Number of input IDs not present in alias or reference (ref) files", fill = "") +
  theme(legend.position = "bottom")
  

df2 <- read.csv("chunks.csv",
                header = F) %>%
  separate(V1, into = c("out", "piece","dir"), sep = "_") %>%
  separate(dir, into = c("term", "widget"), sep = "/") %>%
  select(term, widget, V2) %>%
  mutate(V1 = paste(term, widget, sep = "-"))
head(df2)

ggplot(df2, aes(x = V1, y = V2, fill = term)) +
  geom_bar(stat = "identity") +
  scale_y_continuous(labels = scales::comma) +
  coord_flip()  +
  theme(legend.position = "bottom")


ggplot(df2, aes(x = V1, y = V2, fill = term)) +
  geom_bar(stat = "identity") +
  scale_y_continuous(labels = scales::comma) +
  theme(legend.position = "bottom") +
  coord_flip() +
  geom_text(aes(label = V2), hjust = 0, size = 3) +
  labs(subtitle = "Number of json files generated", fill = "", y = "Count", x = "Widget")
