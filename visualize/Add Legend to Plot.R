library(ggplot2)
library(extrafont)
library(cowplot)

setwd('C://Users/matt/mine-food-security-tex/img/')

loadfonts(device = 'win')

nodes <- expand.grid(`Food Security Pillar: ` =c("Availability  ", "Access    ", 'Utilization  ', 'Stability'),
                     x=c(1, 2),
                     y=c(1, 2))

p <- ggplot() + 
  geom_point(data=nodes, aes(x=x, y=y, color=`Food Security Pillar: `), size=10) + 
  scale_color_manual(values=c('#9183e2', '#e7663b', '#67a030', '#e558b2')) + 
  theme_bw() + 
  theme(text=element_text(size=15, family='Arial'),
        legend.position = 'bottom',
        legend.background = element_blank(),
        legend.box.background = element_rect(colour = "black"),
        legend.spacing.x = unit(0, 'cm'))

l <- get_legend(p)

ggsave(l, filename='legend.png', height=0.75, width=12, units = 'in', dpi=210)

#Image must be saved in Gephi as 2524x2524 with a 2% margin

#Image Magick doesnt work in R because of PATH issues

#So in a terminal, run:

#convert Gephi_graph.png -crop 2524x1162+0+720 out.png
#convert out.png legend.png -append graph_legend.png



