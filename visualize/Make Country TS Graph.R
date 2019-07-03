library(tidyverse)
library(readxl)
library(zoo)
library(cowplot)

setwd('G://My Drive/mine-food-security')

abstracts <- read.csv('abstracts_final.csv', stringsAsFactors = F) %>%
  mutate(ind=seq(0, nrow(.)-1)) %>%
  select(ind, Year, EID)

loc <- read.csv('Abstract_locations_classified.csv', stringsAsFactors=F) %>%
  select(EID, con_verdict)

abstracts_loc <- merge(abstracts, loc, all.x=T, all.y=F) %>%
  filter(con_verdict %in% c('Africa', 'Asia', 'First World', 'LAC'))

abstracts_loc$con_verdict[abstracts_loc$con_verdict=="First World"] <- 'HICs'

alldf <- expand.grid(seq(min(abstracts_loc$Year), 2018), unique(abstracts_loc$con_verdict))
names(alldf) <- c('Year', 'con_verdict')

ts <- abstracts_loc %>% 
  group_by(Year, con_verdict) %>%
  summarize(value=n()) %>%
  merge(alldf, all.x=T, all.y=T) %>%
  mutate(value = ifelse(is.na(value) | is.nan(value), 0, value)) %>%
  group_by(con_verdict) %>%
  arrange(Year) %>%
  mutate(value = rollapply(value, 5, FUN=mean, na.rm=TRUE, fill=NA, partial=TRUE)) %>%
  ungroup %>%
  group_by(Year) %>%
  mutate(value=value/sum(value))


#Time Series
ts_plot <- ggplot(ts) + geom_area(aes(x=Year, y=value, fill=con_verdict)) + 
  scale_x_continuous(expand=c(0,0), breaks=c(1985, 1995, 2005, 2015)) + 
  scale_y_continuous(expand=c(0,0)) +
  scale_fill_brewer(palette = "Set3") + 
  guides(fill=guide_legend(title="")) + 
  ylab('Proportion') + 
  xlab('') + 
  theme(legend.direction = "horizontal",
        legend.position = c(0.5, -0.15),
        legend.justification = 'center',
        plot.margin = unit(c(0, 0.25, 0.70, 0.25), "cm"))

hist <- ggplot(abstracts_loc) + 
  geom_histogram(aes(x=Year), fill='#888888', color='#000000', binwidth=1) + 
  scale_x_continuous(expand=c(0,0)) + 
  scale_y_continuous(expand=c(0,0), breaks = c()) +
  ylab('') + 
  xlab('') +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        panel.background=element_blank(),
        panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),
        plot.background=element_blank(),
        plot.margin = unit(c(0.25, 0.25, -0.11, 0.25), "cm"))

plot_grid(plotlist=list(hist, ts_plot), align='v', ncol=1, nrow=2, rel_heights=c(0.15,1), axis='rl')

ggsave("C:/Users/matt/mine-food-security-tex/img/ByContinent-Year.png", width = 8, height = 4, units="in")
