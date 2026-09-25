### DISC SIMULATION DEMONSTRATION PLOT ###

## Plot of paired points inside a disc to visually demonstrate the context of
## the simulation experiment.
# Check tidyverse is installed

if (!requireNamespace("tidyverse")) {
  stop(
    "Please install the 'tidyverse' package"
  )
}

# Load tidyverse packages

library(tidyverse)


# Generate 200 points uniformly inside a unit disc

points <- tibble(
  id = 1:200,
  r = sqrt(runif(200)),
  theta = runif(200, 0, 2 * pi)
) %>%
  mutate(
    x = r * cos(theta),
    y = r * sin(theta)
  )


# Pair the points sequentially, weighting by distance
# This is just a visual demonstration, and does not reflect a true gravity model

remaining <- points$id

connections <- tibble(
  id1 = integer(),
  id2 = integer()
)

while (length(remaining) > 0) {
  
  # Pick one point at random
  id1 <- sample(remaining, 1)
  
  # Coordinates of that point
  p1 <- points %>%
    filter(id == id1)
  
  # Find all possible partners
  candidates <- points %>%
    filter(id %in% remaining, id != id1) %>%
    mutate(
      distance = sqrt(
        (x - p1$x)^2 +
          (y - p1$y)^2
      ),
      
      # Quasi-impedance function as weighting
      weight = exp(-5*distance)
    )
  
  # Pick one partner using weighted sampling
  partner <- candidates %>%
    slice_sample(
      n = 1,
      weight_by = weight
    ) %>%
    pull(id)
  
  # Store the connection
  connections <- bind_rows(
    connections,
    tibble(
      id1 = id1,
      id2 = partner
    )
  )
  
  # Remove both points from the pool
  remaining <- setdiff(
    remaining,
    c(id1, partner)
  )
}


# -----------------------------
# Add coordinates to connections
# -----------------------------

connections <- connections %>%
  left_join(
    points %>%
      select(id1 = id, x1 = x, y1 = y),
    by = "id1"
  ) %>%
  left_join(
    points %>%
      select(id2 = id, x2 = x, y2 = y),
    by = "id2"
  )

# Create circle 

disc <- tibble( theta = seq(0, 2 * pi, length.out = 500) ) %>% 
  mutate( x = cos(theta), y = sin(theta) )

# Generate plot

plot <- ggplot() +
  
  # Circular boundary 
  geom_path( 
    data = disc, 
    aes(x, y), 
    linewidth = 0.8 ) +
  
  # Connections between pairs
  geom_segment(
    data = connections,
    aes(
      x = x1,
      y = y1,
      xend = x2,
      yend = y2
    ),
    linewidth = 0.35,
    alpha = 0.35
  ) +
  
  # Origins
  geom_point(
    data = connections,
    aes(x1, y1),
    size = 1.5,
    colour = "blue"
  ) +
  
  #Destinations
  geom_point(
    data = connections,
    aes(x2, y2),
    size = 1.5,
    colour = "green"
  ) +
  
  # Format the plot
  coord_equal(
    xlim = c(-1, 1),
    ylim = c(-1, 1)
  ) +
  
  theme_void()

ggsave("output/disc_plot.png",plot, width = 6, height = 6, dpi = 300)
