suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(scales))

df <- read.csv("logs/skipped.csv", header = F)  %>%
  mutate(widget = paste(V2, V1, sep = "\n")) %>%
  group_by(V1, V2, V4, widget) %>% 
  summarize(count = n())

p1 <- ggplot(df, aes(x = widget, y = count, fill = V2)) +
  geom_bar(stat = "identity") +
  scale_y_log10() +
  coord_flip() +
  facet_wrap(~V4) +
  labs(subtitle = "Number of input IDs not present in alias or reference (ref) files", fill = "") +
  geom_text(aes(label = count), hjust = 0, size = 3) +
  theme(legend.position = "bottom")

print("Saving plot of skipped IDs.")

png(file = "logs/skipped.png")
plot(p1)
dev.off()

df2 <- read.csv("logs/chunks.csv",
                header = F) %>%
  separate(V1, into = c("out", "piece","dir"), sep = "_") %>%
  separate(dir, into = c("term", "widget"), sep = "/") %>%
  select(term, widget, V2) %>%
  mutate(V1 = paste(term, widget, sep = "-"))

p2 <- ggplot(df2, aes(x = V1, y = V2, fill = term)) +
  geom_bar(stat = "identity") +
  scale_y_continuous(labels = scales::comma) +
  theme(legend.position = "bottom") +
  coord_flip() +
  geom_text(aes(label = V2), hjust = 0, size = 3) +
  labs(subtitle = "Number of json files generated", fill = "", y = "Count", x = "Widget")


print("Saving plot of json files generated.")

png(file = "logs/chunks.png")
plot(p2)
dev.off()