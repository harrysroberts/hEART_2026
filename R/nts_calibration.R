### NTS CALIBRATION ###

## 1) Calibrates an impedance function for National Travel Survey recorded 
## travel times in England using WMDC, and plots this function against the 
## empirical survival curve.
##
## Required data: National Travel Survey trip data saved to 
## `input/raw/UKDA-5340-tab/tab/trip_eul_2002-2024.tab`
##
## 2) Computes accessibility using both the WMDC-calibrated function and the 
## empirical survival curve as the impedance function, and plots this for the
## city of Leeds, UK.

required <- c("tidyverse","sf","patchwork","grid","pak","utils")

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

# Installs losdos if not already installed
if (!requireNamespace("losdos", quietly = TRUE)) {
  
  answer <- utils::menu(
    c("Yes", "No"),
    title = paste(
      "The package 'losdos' is not installed.",
      "Install it now from GitHub (harrysroberts/wmdc)?"
    )
  )
  
  if (answer == 1) {
    
    pak::pak("harrysroberts/losdos")
    
  } else {
    stop(
      "Package 'losdos' is required to run this script.",
      call. = FALSE
    )
  }
}

library(tidyverse)
library(sf)
library(patchwork)
library(grid)


## 1) Calibrating NTS data

# Extract marginal impedance distribution and survival counts from NTS

marginal_dist <- read_tsv("input/raw/UKDA-5340-tab/tab/trip_eul_2002-2024.tab") %>%
  filter(
    SurveyYear <= 2019,
    TripPurpFrom_B01ID == 23, #from home
    TripPurpTo_B01ID == 1 #to work
  ) %>%
  select(
    TripTotalTime
  ) %>%
  group_by(TripTotalTime) %>%
  summarise(
    count = n()
  ) %>%
  arrange(TripTotalTime) %>%
  mutate(
    S = rev(cumsum(rev(count))) / sum(count)
  )

# WMDC calibration

wmdc_result <- marginal_dist  %>%
  select(TripTotalTime,count) %>%
  wmdc::wmdc()

marginal_dist <- marginal_dist %>%
  mutate(f_WMDC = wmdc_result$impedance_function(TripTotalTime))
  

# Plot impedance decay curve against observed survival counts

x <- seq(0, 60, length.out = 1000)

plot <- ggplot() +
  
  # Axes
  geom_hline(yintercept = 0, linewidth = 0.5, colour = "black") +
  geom_vline(xintercept = 0, linewidth = 0.5, colour = "black") +
  
  # Curves
  geom_line(
    aes(x, wmdc_result$impedance_function(x)),
    colour = "blue",
    linewidth = 0.8
  ) +
  
  geom_line(
    aes(
      c(0, marginal_dist$TripTotalTime[marginal_dist$TripTotalTime <= 60]),
      c(1, marginal_dist$S[marginal_dist$TripTotalTime <= 60])
    ),
    colour = "red",
    linewidth = 0.8
  ) +
  
  # Format
  
  scale_x_continuous(
    name = "Travel time (minutes)",
    limits = c(0, 60),
    breaks = seq(0, 60, by = 10),
    expand = c(0, 0)
  ) +
  
  scale_y_continuous(
    limits = c(0, 1.01),
    expand = c(0, 0)
  ) +
  
  theme_minimal(base_size = 18) +
  
  theme(
    axis.title.x = element_text(),
    axis.title.y = element_blank(),
    axis.line = element_blank(),
    axis.ticks = element_line(linewidth = 0.5),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )

# Save plot to output folder

ggsave("output/impedance_functions_graph.png",plot,dpi = 300,width = 8,height = 4)


## 2) Computing and plotting accessibility measures
## Requires OS-MRN network dataset in input/raw/osmrn.gpkg

# Load census output areas

output_areas <- st_read("input/raw/Output_Areas_Dec_2011_Boundaries_EW_BGC_2022_-4410048714460462685.gpkg")

# Extract Leeds boundary

boundaries <- st_read("input/raw/LAD_MAY_2025_UK_BFC_V2_6634550694215771101.gpkg")

leeds_boundary <- boundaries %>%
  filter(LAD25NM %in% c("Leeds")) %>%
  st_union()

# Writes boundary to the input/raw folder, as required by losdos package

st_write(leeds_boundary, "input/raw/boundary.gpkg", delete_dsn = TRUE)

# Extract OA centroids within Leeds boundary

leeds_oa_centroids <- st_centroid(output_areas) %>%
  st_filter(leeds_boundary, .predicate = st_within) %>%
  mutate(
    easting = st_coordinates(.)[,1],
    northing = st_coordinates(.)[,2]
  ) %>%
  rename(`id` = `OA11CD`) %>%
  select(id, easting, northing) %>%
  st_drop_geometry()

# Compute travel times within Leeds using losdos package

leeds_travel_times <- losdos::osmrn_matrix_attributes(
  origins = leeds_oa_centroids,
  destinations = leeds_oa_centroids,
  period = c("MoFr07000900"),
  use_cache = TRUE
)

# Load Leeds workplace data

leeds_destination_data <- read_csv("input/raw/workplace_population_yorkshire_humber.csv") %>%  
  rename(
    id = geography,
    D = `Population: All usual residents aged 16 to 74; measures: Value`
  ) %>%
  right_join(leeds_oa_centroids, by = "id") %>%
  select(id,D)

# Add time = 0 point to data

marginal_dist <- marginal_dist %>% 
  select(TripTotalTime,f_WMDC,S) %>%
  bind_rows(
    tibble(
      TripTotalTime = 0,
      f_WMDC = 1,
      S = 1
    )
  )

## Compute accessibilities and scale based on the mean of each set

accessibilities <- leeds_travel_times %>%
  left_join(leeds_destination_data, by = join_by(destination == id)) %>%
  mutate(time = round(car_time)) %>%
  left_join(marginal_dist, by = join_by(time == TripTotalTime)) %>%
  group_by(origin) %>%
  summarise(
    accessibility_WMDC = sum(D*f_WMDC),
    accessibility_S = sum(D*S)
  ) %>%
  mutate(
    scaled_accessibility_WMDC = accessibility_WMDC/mean(accessibility_WMDC),
    scaled_accessibility_S = accessibility_S/mean(accessibility_S),
  )

# Set limits for the scaling

lims <- range(
  c(accessibilities$scaled_accessibility_WMDC,
    accessibilities$scaled_accessibility_S),
  na.rm = TRUE
)

## Plot accessibilities using both impedance functions

plot_WMDC <- accessibilities %>%
  left_join(output_areas %>% select(OA11CD,SHAPE), by = join_by("origin" == "OA11CD")) %>%
  st_as_sf() %>%
  ggplot() +
  geom_sf(aes(fill = scaled_accessibility_WMDC, colour = scaled_accessibility_WMDC)) +
  scale_fill_continuous(name = "Accessibility", palette = "Greens",limits = lims) +
  scale_colour_continuous(name = "Accessibility", palette = "Greens",limits = lims) +
  theme_void()

plot_S <-  accessibilities %>%
  left_join(output_areas %>% select(OA11CD,SHAPE), by = join_by("origin" == "OA11CD")) %>%
  st_as_sf() %>%
  ggplot() +
  geom_sf(aes(fill = scaled_accessibility_S, colour = scaled_accessibility_S)) +
  scale_fill_continuous(name = "Accessibility", palette = "Greens",limits = lims) +
  scale_colour_continuous(name = "Accessibility", palette = "Greens",limits = lims) +
  theme_void() 

plot <- (plot_WMDC + plot_S) + plot_layout(guides = "collect")

# Write to file

ggsave("output/accessibility_plot.png", plot, width = 8, height = 4, dpi=300)

