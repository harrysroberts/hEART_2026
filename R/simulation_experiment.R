### SIMULATION EXPERIMENT ###

## Experiment to generate a trip distribution inside a disc with a known
## impedance function, and test the ability of WMDC to recover the input 
## parameter, plotting the accuracy of results against study area and density

# Check packages are installed
required <- c("tidyverse","scales","pak","utils")

missing <- required[
  !vapply(required, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing) > 0) {
  stop(
    "Please install the following packages: ",
    paste(missing, collapse = ", ")
  )
}

# Installs wmdc if not already installed
if (!requireNamespace("wmdc", quietly = TRUE)) {
  
  answer <- utils::menu(
    c("Yes", "No"),
    title = paste(
      "The package 'wmdc' is not installed.",
      "Install it now from GitHub (harrysroberts/wmdc)?"
    )
  )
  
  if (answer == 1) {
    
    pak::pak("harrysroberts/wmdc")
    
  } else {
    stop(
      "Package 'wmdc' is required to run this script.",
      call. = FALSE
    )
  }
}

# Load tidyverse packages
library(tidyverse)

# Arbitrarily set lambda = 1
lambda = 1

# Define impedance function
f <- function(dist, lambda){
  exp(-lambda * dist)
}

# Simulates N origins and destinations in a disc radius R and assigns a trip
# distribution based on a doubly-constrained gravity model, then calibrates
# this using WMDC

calibrate_simulation <- function(R,N,lambda) {
  
  if(N==0){
    return(list(estimate=NA))
  }
  
  #Uniformly distributed origins
  
  origins <- tibble(
    origin_id = 1:N,
    r  = sqrt(runif(N, 0, R^2)), #sqrt to create triangular distribution, ensuring uniformity over the area of the disc.
    theta = runif(N, 0, 2*pi)
  ) 
  
  #Uniformly distributed origins
  destinations <- tibble(
    destination_id = 1:N,
    r  = sqrt(runif(N, 0, R^2)),
    theta = runif(N, 0, 2*pi)
  )
  
  # Create adjacency list of pairs with distance
  pairs <- crossing(
    origins %>% rename(origin_r = r, origin_theta = theta),
    destinations %>% rename(destination_r = r, destination_theta = theta)
  ) %>%
    mutate(
      dist = sqrt(
        origin_r^2 + destination_r^2 - 2 * origin_r * destination_r * cos(origin_theta - destination_theta)
      )
    )
  
  # Iterative proportional fitting to simulate a trip distribution
  
  impedance_matrix <- pairs %>%
    mutate(f = f(dist,lambda)) %>%
    select(origin_id,destination_id,f) %>%
    pivot_wider(names_from = destination_id, values_from = f) %>%
    column_to_rownames("origin_id") %>%
    as.matrix()
  
  A <- rep(1, N)
  B <- rep(1, N)
  
  for (iter in seq_len(1000)) {
    A_new <- 1 / as.vector(impedance_matrix %*% B)
    B_new <- 1 / as.vector(t(impedance_matrix) %*% A_new )
    
    delta <- max(abs(A_new - A) / A, abs(B_new - B) / B)
    A <- A_new
    B <- B_new
    
    if (delta < 1e-6) {
      message("Converged after ", iter, " iterations (delta = ", signif(delta, 3), ")")
      break
    }
  }
  
  # Use the fitted distribution as probabilities to assign a destination to each
  # origin. Note that not all destinations will form part of a trip - this is
  # due to the probabilistic nature of the assignment.
  
  assignments <- pairs %>% 
    mutate(
      p = A[origin_id] * B[destination_id] * f(dist, lambda)
    ) %>%
    select(origin_id, destination_id, dist, p) %>%
    group_by(origin_id) %>%
    slice_sample(n = 1, weight_by = p) %>%
    ungroup()
  
  # estimate lambda using wmdc
  
  model <- assignments %>%
    select(dist) %>%
    mutate(count=rep(1, nrow(assignments))) %>%
    wmdc::wmdc()
  
  list(
    estimate = model$parameters$lambda
    )
  
}

# Peform calibrated simulation over multiple R, N combinations
res <- list()

for (i in 1:7) {
  res[[i]] <- tibble(
    R = 10^(seq(0, 20, by = 1) / 10) #R = 1, 10^0.1, 10^0.2, ..., 10^1.9, 100
  ) %>%
    mutate(
      N = round(10^(1+0.5*(i-1))), #N = 10, 10√10, 100, 100√10, 1000, 1000√10, 10000
      estimate = map2(
        R,
        N,
        ~ calibrate_simulation(.x, .y, lambda = lambda)
      )
    ) %>%
    unnest_wider(estimate)
}

# Combine into a single data frame and compute density

combined <- map_dfr(1:7, function(i) {
  res[[i]] %>%
    mutate(d = N/(pi*(lambda*R)^2))
})

# Define bands for graph colouring

levels_band <- c(
  "< 0.33",
  "0.33-0.50",
  "0.50-0.67",
  "0.67-0.91",
  "0.91-1.10",
  "1.10-1.50",
  "1.50-2.00",
  "2.00-3.00",
  "> 3.00"
)

# Plot simulation accuracy against scaled area and density

plot <- combined %>%
  filter(d >= 0.01 & d <= 110) %>%
  mutate(
    estimate_band = case_when(
      estimate < 1/3   ~ "< 0.33",
      estimate < 1/2   ~ "0.33-0.50",
      estimate < 1/1.5 ~ "0.50-0.67",
      estimate < 1/1.1 ~ "0.67-0.91",
      estimate <= 1.10 ~ "0.91-1.10",
      estimate <= 1.50 ~ "1.10-1.50",
      estimate <= 2.00 ~ "1.50-2.00",
      estimate <= 3.00 ~ "2.00-3.00",
      TRUE             ~ "> 3.00"
    ),
    estimate_band = factor(estimate_band, levels = levels_band)
  ) %>%
  ggplot(aes(pi*(lambda*R)^2, d, fill = estimate_band)) +
  geom_point(
    shape = 21,
    colour = "black",
    stroke = 0.3,
    size = 12
  ) +
  scale_x_log10(
    labels = scales::label_number()
  ) +
  scale_y_log10(
    labels = scales::label_number()
  ) +
  labs(
    x = expression("Scaled area " ~ A == pi * (lambda * R)^2),
    y = expression(
      "Density of origins/destinations " ~
        rho == frac(N, pi * (lambda * R)^2)
    )
  ) +
  scale_fill_manual(
    name = expression(
      "Accuracy   " * hat(lambda) / lambda
    ),
    values = c(
      "< 0.33"    = "red4",
      "0.33-0.50" = "red3",
      "0.50-0.67" = "red",
      "0.67-0.91" = "pink",
      
      "0.91-1.10" = "white",
      
      "1.10-1.50" = "lightblue",
      "1.50-2.00" = "dodgerblue",
      "2.00-3.00" = "blue3",
      "> 3.00"    = "blue4"
    )
  ) +
  guides(
    fill = guide_legend(
      reverse = TRUE,
      override.aes = list(size = 7)
      )
    ) +
  theme_minimal(base_size = 16) +
  theme(
    legend.position = "right",
    legend.justification = "top",
    legend.title = element_text(hjust = 1),
    legend.box.margin = margin(l = -40),
    axis.line = element_line(linewidth = 0.5, colour = "black")
    )

# Save plot

ggsave("output/heatmap.png",plot, width = 9, height = 6, dpi = 300)
