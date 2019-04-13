setwd('G://My Drive/mine-food-security')

library(dplyr)

###Already ran:

# abs <- read.csv('abstracts.csv')
# loc <- read.csv('Locations.csv')
# 
# abs <- merge(abs, loc)
# 
# sel <- abs[sample(1:nrow(abs), 300, replace = F), c('EID', 'loc_title', 'Title', 'loc_keywords', 'keywords', 'loc_abstract', 'text')]
# 
# write.csv(sel, 'Sample_Validation_Locations.csv', row.names=F)

###Now we have a different corpus of abstracts
###So get the training data that was already in the corpus
###And add a few more so we have 300 again

abs <- read.csv('abstracts_final.csv')
loc <- read.csv('Locations.csv')

abs <- merge(abs, loc)

abs <- abs[ , c('EID', 'loc_title', 'Title', 'loc_keywords', 'keywords', 'loc_abstract', 'text')]

val <- read.csv('Sample_Validation_Locations.csv')
val <- val[val$EID %in% abs$EID, c('EID', 'Continent')]
val <- merge(val, abs, all.x=T, all.y=F)

abs <- abs[!abs$EID %in% val$EID, ]
sel <- abs[sample(1:nrow(abs), 127, replace=F), ]

fin <- bind_rows(val, sel)

write.csv(fin, 'Sample_Validation_Locations.csv', row.names=F)
