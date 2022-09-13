suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(scales))

df <- read.csv("logs/skipped.csv", header = F)  %>%
  mutate(widget = paste(V2, V1, sep = "-")) %>%
  group_by(V2, widget, V4) %>% 
  summarize(count = n())
head(df)

p1 <- ggplot(df, aes(x = widget, y = count, fill = V2)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  facet_wrap(~V4, nrow = 1) +
  labs(subtitle = "Number of input IDs not present in alias or reference (ref) files", fill = "") +
  geom_text(aes(label = count), hjust = 0.5, size = 3) +
  theme(legend.position = "bottom")
p1

print("Saving plot of skipped IDs.")

png(file = "logs/skipped.png", res = 300, width = 7, height = 4, units = "in")
plot(p1)
dev.off()

df2 <- read.csv("logs/chunks.csv",
                header = F) %>%
  separate(V1, into = c("out", "piece","dir"), sep = "_") %>%
  separate(dir, into = c("term", "widget"), sep = "/") %>%
  mutate(V1 = paste(term, widget, sep = "-")) %>%
  select(term, V1, V2) 
head(df2)

p2 <- ggplot(df2, aes(x = V1, y = V2, fill = term)) +
  geom_bar(stat = "identity") +
  scale_y_continuous(labels = scales::comma) +
  theme(legend.position = "none") +
  coord_flip() +
  geom_text(aes(label = V2), hjust = 0.5, size = 3) +
  labs(subtitle = "Number of json files generated", fill = "", y = "Count", x = "Widget") +
  facet_grid(rows = vars(term), scales = "free", space = "free")
p2

print("Saving plot of json files generated.")

png(file = "logs/chunks.png", res = 300, width = 7, height = 4, units = "in")
plot(p2)
dev.off()