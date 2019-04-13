library(readxl)
library(tidyverse)
library(xtable)

setwd('G://My Drive/mine-food-security')

simpleCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), substring(s, 2),
        sep="", collapse=" ")
}

dat <- read_xlsx('CTM40 - Topics.xlsx') %>% 
  arrange(`New group names`, desc(Perc_of_Corpus)) %>%
  select(Perc_of_Corpus, `New group names`, `Topic Name`, Keywords) %>%
  rowwise() %>%
  mutate(Perc_of_Corpus = round(Perc_of_Corpus, 1),
         Keywords = paste0(str_split(Keywords, '; ')[[1]][1:4], collapse=' ')) %>%
  rename(`\\%` = Perc_of_Corpus,
         `Theme` = `New group names`,
         `Topic Label` = `Topic Name`,
         `Top Four Words` = Keywords) %>%
  mutate(Theme = simpleCap(Theme),
         `Topic Label` = paste0('BOLD', simpleCap(`Topic Label`)),
         `Top Four Words` = simpleCap(`Top Four Words`))

bold <- function(x) {gsub('_', '-', gsub('BOLD(.*)',paste('\\\\textbf{\\1','}'),x))}


tab <- xtable(dat, caption='Summary of identified topics', label='tab:topics', 
       align=c('l', 'l', 'r', 'r', 'r'))
names(tab) <- names(dat)
print(tab, file='C://Git/mine-food-security-tex/tables/topics.tex',
      include.rownames=F, include.colnames=T, sanitize.text.function=bold, 
      size="\\fontsize{9pt}{10pt}\\selectfont")
