### LINEAR GROWTH DEMONSTRATION PLOT ###

## Produces a plot to demonstrate linear growth of destination
## availability with distance in a uniform plane

# Check tidyverse is installed

if (!requireNamespace("tidyverse")) {
  stop(
    "Please install the 'tidyverse' package"
  )
}

# Load tidyverse packages

library(tidyverse)

# Set seed so the count is fixed
# set.seed(9999)

# Generate a uniform distribution of points in a square

points_df <- tibble(
  x = runif(1000, -5, 5),
  y = runif(1000, -5, 5)
) %>%
  
  # Tag those points with 2 or 4 if their distance from the centre rounds to 2
  # or 4 respectively.
  
  mutate(
    dist = sqrt(x^2 + y^2),
    dist_round = round(dist),
    group = case_when(
      dist_round == 2 ~ "2 km",
      dist_round == 4 ~ "4 km",
      TRUE ~ "Other"
    )
  )

counts <- points_df %>%
  group_by(group) %>%
  summarise(count = n())

count_text_2km <- str_c("Count = ",counts$count[1])

count_text_4km <- str_c("Count = ",counts$count[2])

# Define circles with radius 2 and 4

theta <- seq(0, 2 * pi, length.out = 400)

circle_df <- bind_rows(
  tibble(x = 2 * cos(theta), y = 2 * sin(theta), r = "2 km"),
  tibble(x = 4 * cos(theta), y = 4 * sin(theta), r = "4 km")
)

# Generate plot

plot <- ggplot() +
  
  # Plot points, colouring those rounding to 2 or 4
  geom_point(
    data = points_df,
    aes(x, y, colour = group),
    size = 1,
    alpha = 0.7,
    show.legend = FALSE
  ) +
  
  # Plot circles
  geom_path(
    data = circle_df,
    aes(x, y, colour = r),
    linewidth = 1,
    show.legend = FALSE
  ) +
  
  # Plot origins
  geom_point(aes(0, 0), size = 4) +
  
  # Label origin
  annotate(
    "text",
    x = 0.15, y = -0.15,
    label = "i",
    size = 12,
    family = "serif",
    fontface = "italic"
  ) +
  
  # Generate arrows showing radii of 2 and 4
  annotate(
    "segment",
    x = 0, y = 0, xend = 2* cos(3*pi/4), yend = 2 * sin(3*pi/4),
    arrow = arrow(length = unit(0.2, "cm")),
    linewidth = 0.8
  ) +
  annotate(
    "segment",
    x = 0, y = 0, xend = 4* cos(pi/4), yend = 4*sin(pi/4),
    arrow = arrow(length = unit(0.2, "cm")),
    linewidth = 0.8
  ) +
  
  # Generate labels for
  annotate("text", x = -0.3, y = 1, label = "2 km",size=6) +
  annotate("text", x = 1.7, y = 2.4, label = "4 km",size=6) +
  #other labels
  annotate("text", x = -1.2, y = -2.2, label = count_text_2km, colour = "#0072B2",fontface="bold",size=6) +
  annotate("text", x = -2.5, y = -4, label = count_text_4km, colour="#D55E00",fontface="bold",size=6) +
  # geometry
  coord_equal(xlim = c(-5, 5), ylim = c(-5, 5)) +
  scale_colour_manual(
    values = c(
      "2 km" = "#0072B2",
      "4 km" = "#D55E00",
      "Other" = "grey70"
    )
  ) +
  # kill all plot furniture
  theme_void()

ggsave("output/uniform.png",plot,dpi = 300,width = 6,height = 6)

