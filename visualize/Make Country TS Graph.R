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


histdf <- abstracts_loc %>%
  group_by(Year) %>%
  summarize(count=n())

#Time Series
ts_plot <- ggplot(ts) + geom_area(aes(x=Year, y=value, fill=con_verdict)) + 
  scale_x_continuous(expand=c(0,0), limits = c(1981, 2018)) + 
  scale_y_continuous(expand=c(0,0), breaks=c(0.25, 0.5, 0.75, 1)) +
  scale_fill_brewer(palette = "Set3") + 
  guides(fill=guide_legend(title="")) + 
  ylab('Proportion') + 
  xlab('') + 
  theme_bw() + 
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        legend.position = 'none',
        plot.margin = unit(c(0.25, 0.25, -0.06, 0.25), "cm"))

ts_leg <- get_legend(ts_plot + theme(legend.direction = "horizontal",
                                     legend.position = c(0.5, 0.9)))

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
        plot.margin = unit(c(-0.06, 0.25, 0, 0.25), "cm"))

plot_grid(plot_grid(plotlist=list(ts_plot, hist), align='v', ncol=1, nrow=2, rel_heights=c(1,0.3), axis='rl',
                    labels = "AUTO", label_x = c(0.08, 0.08), label_y=c(0.97, 0.98)),
          ts_leg, ncol=1, rel_heights=c(1, 0.05))

ggsave("C:/Users/matt/mine-food-security-tex/img/ByContinent-Year.eps", width = 8, height = 5, units="in")
