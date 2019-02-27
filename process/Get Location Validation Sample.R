setwd('C://Git/mine-food-security/data')

abs <- read.csv('abstracts.csv')
loc <- read.csv('Locations.csv')

abs <- merge(abs, loc)

sel <- abs[sample(1:nrow(abs), 300, replace = F), c('EID', 'loc_title', 'Title', 'loc_keywords', 'keywords', 'loc_abstract', 'text')]

write.csv(sel, 'Sample_Validation_Locations.csv', row.names=F)
