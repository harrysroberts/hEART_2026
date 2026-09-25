### NATIONAL TRAVEL SURVEY HISTOGRAM ###

## Produces a histogram showing the marginal distribution of travel time for
## home-work trips in England recorded between 2002 and 2019

# Check tidyverse is installed

if (!requireNamespace("tidyverse")) {
  stop(
    "Please install the 'tidyverse' package"
  )
}

# Load tidyverse packages

library(tidyverse)

# Load trip data from the National Travel Survey, filter for home work trips
# between 2002 and 2019 (pre-COVID), and select travel times

trips <- read_tsv("input/raw/UKDA-5340-tab/tab/trip_eul_2002-2024.tab") %>%
  filter(
    SurveyYear <= 2019,
    TripPurpFrom_B01ID == 23, #from home
    TripPurpTo_B01ID == 1 #to work
  ) %>%
  select(
    TripTotalTime
  )

# Plot histogram of travel times 

plot <- trips %>% 
  ggplot(aes(x = TripTotalTime)) +
  geom_histogram(binwidth = 15, boundary = 0, closed = "left", fill = "#00D0A0", color = "black") +
  scale_x_continuous(breaks = seq(0, 120, by = 20), limits = c(0, 120)) +
  scale_y_continuous(breaks = seq(0, 150000, by = 20000), labels = scales::comma_format(scale = 0.001)) +
  labs(x = "Travel time (minutes)", y = "No. of trips (thousands)") +
  theme_minimal() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

#Save in output folder

ggsave(plot, filename = "output/impedance_histogram.png", width = 4, height = 3, dpi = 300)

