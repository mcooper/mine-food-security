library(tidyverse)
library(readxl)
library(zoo)
library(cowplot)

setwd('G://My Drive/mine-food-security')

abstracts <- read.csv('abstracts_final.csv', stringsAsFactors = F) %>%
  mutate(ind=seq(0, nrow(.)-1)) %>%
  select(ind, Year, EID)

doc_topic <- read.csv('CTMmods/CTM60 - Doc Topic Matrix.csv') %>%
  gather(topic, value, -X) %>%
  mutate(topic = gsub('X', '', topic)) %>%
  rename(ind=X)

labels <- read_excel('CTM60 - Topics_Final Matt Update.xlsx') %>%
  filter(`Topic Name` != '---- Mashup Topic -----') %>%
  select(topic=Topic_Number, Theme=`Group Names`, `FS Theme`=`Food Security category`)

doc_topic_labels <- merge(doc_topic, labels, all.x=FALSE, all.y=T)
doc_topic_labels <- doc_topic_labels %>%
  group_by(ind, Theme) %>%
  summarize(value = mean(value))

all <- merge(doc_topic_labels, abstracts) %>%
  na.omit

alldf <- expand.grid(seq(min(abstracts$Year), max(abstracts$Year)), unique(all$Theme))
names(alldf) <- c('Year', 'Theme')

ts <- all %>% 
  group_by(Year, Theme) %>%
  summarize(value=sum(value)) %>%
  merge(alldf, all.x=T, all.y=T) %>%
  mutate(value = ifelse(is.na(value), 0, value)) %>%
  group_by(Theme) %>%
  arrange(Year) %>%
  mutate(value = rollapply(value, 5, FUN=mean, na.rm=TRUE, fill=NA, partial=TRUE)) %>%
  ungroup %>%
  group_by(Year) %>%
  mutate(value=value/sum(value)) %>%
  data.frame

histdf <- all %>%
  group_by(Year) %>%
  summarize(count=length(unique(EID)))

#Time Series
(ts_plot <- ggplot(ts) + geom_area(aes(x=Year, y=value, fill=Theme)) + 
  scale_x_continuous(expand=c(0,0), breaks=c(1980, 1985, 1990, 1995, 2000, 2005, 2010, 2015)) + 
  scale_y_continuous(expand=c(0,0), breaks=c(0.25, 0.5, 0.75, 1)) +
  scale_fill_brewer(palette = "Set3") + 
  guides(fill=guide_legend(title="")) + 
  ylab('Proportion') + 
  xlab('') + 
  theme_bw() + 
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        legend.position = "none",
        plot.margin = unit(c(0.25, 0.25, -0.05, 0.25), "cm")))

ts_leg <- get_legend(ts_plot + theme(legend.direction = "horizontal",
                                     legend.position = c(0.5, 0.5)))

hist <- ggplot(histdf) + 
    geom_bar(aes(x=Year, y=count), fill='#888888', color='#000000', stat='identity', width=1) + 
    scale_x_continuous(expand=c(0,0), breaks=c(1985, 1990, 1995, 2000, 2005, 2010, 2015), limits = c(1980.5, 2018.5)) + 
    scale_y_continuous(expand=c(0, 0, 0, 250), breaks = c(0, 1000)) +
    ylab('Count') + 
    xlab('') +
    theme_bw() + 
    theme(panel.background=element_blank(),
          panel.grid.major=element_blank(),
          panel.grid.minor=element_blank(),
          plot.background=element_blank(),
          plot.margin = unit(c(-0.05, 0.25, 0, 0.25), "cm"))

plot_grid(plot_grid(plotlist=list(ts_plot, hist), align='v', ncol=1, nrow=2, rel_heights=c(1,0.3), axis='rl',
                    labels = "AUTO", label_x = c(0.08, 0.08), label_y=c(0.97, 0.98)),
          ts_leg, ncol=1, rel_heights=c(1, 0.1))

ggsave("C:/Users/matt/mine-food-security-tex/img/TimeSeries.eps", width = 9, height = 5, units="in")

