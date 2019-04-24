library(tidyverse)
library(countrycode)
library(ggplot2)

setwd('G://My Drive/mine-food-security')

ghi <- read.csv('Objective Metrics/Global Hunger Index/GHI.csv')
voth <- read.csv('Objective Metrics/FAO Voices of the Hungry/VotH_clean.csv')
gfsi <- read.csv('Objective Metrics/EIU Global Food Security Index/GFSI.csv')
mpc <- read.csv('Mentions_Per_Cap.csv')

ghi$cc <- countrycode(ghi$Country, origin = "country.name", destination = "fips")
voth$cc <- countrycode(voth$Country, origin = "country.name", destination = "fips")
voth$cc[voth$Country=='South Sudan'] <- "OD"
gfsi$cc <- countrycode(gfsi$Country, origin = "country.name", destination = "fips")
mpc$cc <-  countrycode(mpc$ADMIN, origin = "country.name", destination = "fips")
mpc$cc[mpc$ADMIN=='South Sudan'] <- "OD"

all <- Reduce(function(x,y){merge(x, y, all.x=T, all.y=T, by='cc')}, list(ghi, voth, gfsi, mpc))

all$mpc_log <- log(all$Mentions_Per_Cap+1)

sel <- all %>% filter(!is.na(Mod_Prev))

breaks <- seq(0, 6, 1)
labels <- signif(exp(breaks) - 1, 3)

ggplot(sel) + geom_text(aes(x=mpc_log, y=Mod_Prev, label=ADMIN)) + 
  theme_bw() + 
  xlab("Mentions in Academic Literature Per 1 Million Inhabitants") + 
  ylab("Rate of Moderate Food Insecurity") + 
  scale_x_continuous(breaks=breaks, labels=labels) + 
  ggtitle("Comparison with FAO Voices of the Hungry")

ggsave('C://Git/mine-food-security-tex/img/FAO_Compare.png', height=12, width=12)


sel <- all %>% filter(!is.na(GFSI))
sel$GFSI <- 100 - sel$GFSI

ggplot(sel) + geom_text(aes(x=mpc_log, y=GFSI, label=ADMIN)) + 
  theme_bw() + 
  xlab("Mentions in Academic Literature Per 1 Million Inhabitants") + 
  ylab("Global Food Security Index") + 
  scale_x_continuous(breaks=breaks, labels=labels) + 
  scale_y_continuous(breaks=seq(0, 100, 25), labels=100-seq(0, 100, 25)) + 
  ggtitle("Comparison with EIU Global Food Security Indicator")

ggsave('C://Git/mine-food-security-tex/img/GFSI_Compare.png', height=12, width=12)


sel <- all %>% filter(!is.na(GHI2018))

ggplot(sel) + geom_text(aes(x=mpc_log, y=GHI2018, label=ADMIN)) + 
  theme_bw() + 
  xlab("Mentions in Academic Literature Per 1 Million Inhabitants") + 
  ylab("Global Hunger Index") + 
  scale_y_continuous(breaks=seq(0, 100, 25), labels=100-seq(0, 100, 25)) + 
  ggtitle("Comparison with FAO Voices of the Hungry")

ggsave('C://Git/mine-food-security-tex/img/GHI_Compare.png', height=12, width=12)
