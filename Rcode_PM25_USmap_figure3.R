library(ggplot2)
library(sf)
library(data.table)
if (!require(rnaturalearthhires)) {
install.packages("rnaturalearthhires", repos = "http://packages.ropensci.org", type = "source")
}


df_change_pm25 <- read.csv("df_change_pm25.csv")
df_change_pm25$diff <- df_change_pm25$after - df_change_pm25$before

# get USA dataset -- just lower 48 states
states48 <- state.name[!(state.name %in% c('Hawaii'))]
usa <- rnaturalearth::ne_states( 
  country = "United States of America",
  returnclass = 'sf')
usa <- usa[usa$name %in% states48,]
usa$state <- state.abb[match(usa$name, state.name)]

# merge with some data
usa.data <- df_change_pm25
usa.data$name <- usa.data$state
usa.plot <- merge( usa, usa.data, by = 'state')

usa.gg <- ggplot(usa.plot) +
  geom_sf( aes( fill = diff), color = 'grey50', size = .1) +
  scale_fill_gradient2() +
  coord_sf() +
  labs( title = '') +
  theme_minimal() +
  theme( axis.text = element_blank(),
         title = element_text(size = 16, hjust = .5),
         axis.title = element_blank(),
         legend.key.width = unit( .1, 'cm'),
         legend.position = c( .9, .3),
         legend.text = element_text( size = 14),
         legend.title = element_blank(),
         panel.grid = element_blank()
  )
usa.gg

# to save the plot (may want to play with dimensions)
ggsave( "figures/pm25_binarycolormap.png", 
        usa.gg, width = 7, height = 4)
