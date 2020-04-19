library(readxl)
library(tidyverse)
library(xtable)

options(stringsAsFactors=F)

setwd('G://My Drive/mine-food-security')

abs <- read.csv('abstracts_final.csv')

simpleCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), substring(s, 2),
        sep="", collapse=" ")
}

dat <- read_xlsx('CTM60 - Topics_Final Matt Update.xlsx') 

for (i in 1:nrow(dat)){
  print(i)
  ab1_10 <- dat[i, c("Abstract_1", "Abstract_2", 
                     "Abstract_3", "Abstract_4", "Abstract_5", "Abstract_6", "Abstract_7", 
                     "Abstract_8", "Abstract_9", "Abstract_10")] %>%
    gather(Key, text) %>%
    mutate(rank = as.numeric(substr(Key, 10, nchar(Key)))) %>%
    merge(abs %>% 
            select(text, CitationCount, DOI)) %>%
    select(rank, CitationCount, DOI) %>%
    arrange(rank)
  
  if (all(is.na(ab1_10$DOI))){
    stop("All DOI missing on topic", i)
  }
  
  ab1_10 <- ab1_10 %>%
    filter(!is.na(DOI))
  
  res <- character(0)
  while (length(res) == 0){
    
    if (any(ab1_10$CitationCount > 10)){
      doi <- ab1_10$DOI[ab1_10$CitationCount > 10][1]
      ab1_10 <- ab1_10 %>% filter(DOI != doi)
    } else{
      doi <- ab1_10$DOI[ab1_10$CitationCount == max(ab1_10$CitationCount)]
      ab1_10 <- ab1_10 %>% filter(DOI != doi)
    }
    
    res <- system(paste0('doi2bib ', doi), intern = T)
    
  }  
  
  if (i==1){
    cat(res, file = 'newbibs.bib')
  } else{
    cat(res, file = 'newbibs.bib', append = T)
  }
  
  art <- res[grepl('article', res)]
  
  art <- gsub(',', '', gsub('@article{', '', art, fixed=T), fixed=T)
  
  dat$art[i] <- art
}


dat <- dat %>%
  filter(`Topic Name` != '---- Mashup Topic -----') %>%
  arrange(`Group Names`, desc(Perc_of_Corpus)) %>%
  select(Perc_of_Corpus, `Group Names`, `Topic Name`, #`Food Security category`, 
         Keywords, art) %>%
  rowwise() %>%
  mutate(Perc_of_Corpus = round(Perc_of_Corpus, 1),
         Keywords = paste0(str_split(Keywords, '; ')[[1]][1:3], collapse=' ')) %>%
  rename(`\\%` = Perc_of_Corpus,
         `Theme` = `Group Names`,
         #`FS Theme` = `Food Security category`,
         `Topic Label` = `Topic Name`,
         `Top Three Words` = Keywords,
         `Representative Article`=art) %>%
  mutate(Theme = simpleCap(Theme),
         #`FS Theme` = simpleCap(`FS Theme`),
         `Topic Label` = paste0('BOLD', simpleCap(`Topic Label`)),
         `Theme` = gsub('&', '\\&', `Theme`, fixed = TRUE),
         `Top Three Words` = gsub('_', '-', simpleCap(`Top Three Words`)),
         `Representative Article` = paste0('CITEP', `Representative Article`))

#Get DOI, and add a column with the doi as a citep{}

sani <- function(x){
  x <- gsub('BOLD(.*)',paste('\\\\textbf{\\1','}'), x)
  
  x <- gsub(' }', '}', gsub('CITEP(.*)',paste('\\\\citep{\\1','}'), x), fixed=T)
  
  x
}


tab <- xtable(dat, caption='Summary of identified topics', label='tab:topics', 
       align=c('l', 'l', 'r', 'r', 'r', 'r'))
names(tab) <- names(dat)
# print(tab, file='C://Users/matt/mine-food-security-tex/tables/topics.tex',
#       include.rownames=F, include.colnames=T, sanitize.text.function=bold, 
#       size="\\fontsize{9pt}{10pt}\\selectfont")
print(tab, file='topics.tex',
      table.placement='H',
      include.rownames=F, include.colnames=T, sanitize.text.function=sani, 
      size="\\fontsize{8pt}{9pt}\\selectfont")

##Need to add 
# \resizebox{\textwidth}{!}{%
# on line 6
# and add a second } after end{tabular}
# https://tex.stackexchange.com/questions/27097/changing-the-font-size-in-a-table
