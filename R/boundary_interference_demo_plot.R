### BOUNDARY INTERFERENCE DEMONSTRATION PLOT ###

## Produces a geometric image to demonstrate the eventual decay of destination 
## availability as the boundary is reached, and associated distributional plot

# Check packages are installed

required <- c("tidyverse","patchwork")

missing <- required[
  !vapply(required, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing) > 0) {
  stop(
    "Please install the following packages: ",
    paste(missing, collapse = ", ")
  )
}

# Load  packages

library(tidyverse)
library(patchwork)

# Define outer circle properties

outer_radius <- 1
outer_centre <- c(x = 0, y = 0)


# Define point inside the circle

point <- c(x = -1/3, y = 0)

# Define increasing radii of arcs from the point

radii <- seq(
  1/3,
  4/3 * outer_radius,
  length.out = 4
)

# Compute alpha angle

alpha <- atan2(
  point["y"] - outer_centre["y"],
  point["x"] - outer_centre["x"]
)


# Construct arcs of given radii

make_visible_ring <- function(radius, n = 1000) {
  
  k <- (outer_radius^2 - (1/3)^2 - radius^2) /
    (2 * (1/3) * radius)
  
  if (k >= 1) {
    
    theta <- seq(0, 2*pi, length.out = n)
    
  } else if (k <= -1) {
    
    return(tibble())
    
  } else {
    
    cutoff <- acos(k)
    
    theta <- seq(
      alpha + cutoff,
      alpha + 2*pi - cutoff,
      length.out = n
    )
  }
  
  tibble(
    radius = radius,
    theta = theta,
    x = point["x"] + radius * cos(theta),
    y = point["y"] + radius * sin(theta)
  )
}

rings <- map_dfr(radii, make_visible_ring)

# Compute lengths of each arc

arc_lengths <- tibble(
  radius = c(0,radii)
) %>%
  mutate(
    k = (outer_radius^2 - (1/3)^2 - radius^2) /
      (2 * (1/3) * radius),
    
    arc_length = case_when(
      k >= 1  ~ 2 * pi * radius,
      k <= -1 ~ 0,
      TRUE    ~ radius * (2*pi - 2*acos(k))
    )
  )

# Construct outer circle

outer_circle <- tibble(
  theta = seq(0, 2*pi, length.out = 1000),
  x = outer_radius * cos(theta),
  y = outer_radius * sin(theta)
)

# Construct ruler showing radii

ruler_ticks <- tibble(
  x = c(-1/3, 0, 1/3, 2/3, 1),
  label = 0:4
)

ruler_line <- tibble(
  x = c(-1/3, 1),
  y = c(0, 0)
)

# Construct geometric plot

p1 <- ggplot() +
  
  # Draw arcs around point
  geom_path(
    data = rings,
    aes(x, y, group = radius),
    linewidth = 0.8,
    colour = "black",
    lineend = "round"
  ) +
  
  # Draw outer circle
  geom_path(
    data = outer_circle,
    aes(x, y),
    linewidth = 1.4,
    colour = "black"
  ) +
  
  # Draw ruler
  geom_segment(
    data = ruler_line,
    aes(
      x = x[1], y = 0,
      xend = x[2], yend = 0
    ),
    linewidth = 0.5
  ) +
  
  # Draw ruler ticks
  geom_segment(
    data = ruler_ticks,
    aes(
      x = x,
      y = 0,
      xend = x + 0.02,
      yend = -0.02,
    ),
    linewidth = 0.5
  ) +
  
  # Draw ruler labels
  geom_text(
    data = ruler_ticks,
    aes(
      x = x + 0.04,
      y = -0.06,
      label = label
    ),
    size = 6
  ) +
  
  # Draw point location
  geom_point(
    aes(
      x = point["x"],
      y = point["y"]
    ),
    size = 3
  ) +
  
  # Format plot
  coord_fixed(
    xlim = c(-1.05, 1.4),
    ylim = c(-1.05, 1.05),
    expand = FALSE
  ) +
  
  theme_void()

# Draw distributional graph of arc lengths

p2 <- ggplot(
  arc_lengths,
  aes(radius*3, arc_length)
) +
  
  # Draw lines connecting points
  geom_line(
    linewidth = 1
  ) +
  
  # Draw points
  geom_point(
    size = 1.5
  ) +
  
  # Format plot
  
  labs(
    x = "Radius",
    y = "Arc length"
  ) +
  
  theme_minimal(base_size = 18) +
  
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    axis.line = element_line(linewidth = 0.5, colour = "black")
  )

# Combine plots

plot <- p1 / p2 +
  plot_layout(
    heights = c(3, 1)
  )

# Save plot to file

ggsave("output/boundary_interference.png", plot, width = 6, height = 7, dpi=300)

