### p(x), g(x) AND f(x) CURVE PLOTTING ###

## Plots scaled curves of the marginal distribution p(x) against an exponential
## impedance function f(x) and a linear spatial weight function g(x)

# Check packages are installed
required <- c("ggplot2", "grid")

missing <- required[
  !vapply(required, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing) > 0) {
  stop(
    "Please install the following packages: ",
    paste(missing, collapse = ", ")
  )
}

# Load packages
library(ggplot2)
library(grid)

# Define impedances x

x <- seq(0, 30, length.out = 1000)

# Linear spatial weight function
g <- x

# Exponential impedance decay
f <- exp(-0.15 * x)

# Impedance density
p <- g * f

# Scale for visual comparison

g <- g / max(g)
f <- f / max(f)
p <- p / max(p)

# Plot curves
plot <- ggplot() +
  
  # Axes with arrowheads
  annotate(
    "segment",
    x = 0, y = 0,
    xend = 31, yend = 0,
    linewidth = 1.2,
    colour = "black",
    arrow = arrow(length = unit(0.25, "cm"))
  ) +
  
  annotate(
    "segment",
    x = 0, y = 0,
    xend = 0, yend = 1.10,
    linewidth = 1.2,
    colour = "black",
    arrow = arrow(length = unit(0.25, "cm"))
  ) +
  
  # Curves
  geom_line(
    aes(x, g),
    colour = "#1f77b4",
    linewidth = 1.2
  ) +
  
  geom_line(
    aes(x, f),
    colour = "#d62728",
    linewidth = 1.2
  ) +
  
  geom_line(
    aes(x, p),
    colour = "#2ca02c",
    linewidth = 1.2
  ) +
  
  coord_cartesian(
    xlim = c(0, 36),
    ylim = c(-0.12, 1.12),
    clip = "off"
  ) +
  
  theme_void() +
  
  theme(
    plot.margin = margin(
      t = 20,
      r = 40,
      b = 30,
      l = 20
    )
  )


ggsave("output/pgf_graph.png",plot,dpi = 300,width = 8,height = 6)
