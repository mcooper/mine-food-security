setwd('G://My Drive/mine-food-security')

dat <- read.csv('mod28transformed_coords_nonmetric.csv')

library(ggplot2)

ggplot(dat) + geom_text(aes(x=X0, y=X1, label=X), size=4)
