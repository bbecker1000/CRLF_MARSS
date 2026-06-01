# ==============================================================================
# Project: GOGA California Red-Legged Frog (CRLF) Risk Assessment
# Script: 01_data_prep.R
# Objective: Clean raw survey data and export baseline population trends
# ==============================================================================

if (!require("tidyverse")) install.packages("tidyverse")
library(tidyverse)

# 1. LOAD DATA -----------------------------------------------------------------
egg_data  <- read_csv("data/CRLF_EGG_RAWDATA_V6.csv")
locations <- read_csv("data/CRLF_tblLocations.csv")

# 2. CLEAN AND TRANSFORM -------------------------------------------------------
clean_egg_data <- egg_data %>%
  # Fix text-to-numeric bug for egg counts
  mutate(NumberofEggMasses = as.numeric(NumberofEggMasses)) %>%
  
  # Standardize dates
  mutate(SurveyDate = mdy(SurveyDate)) %>%
  
  # Remove placeholder 2025 data to keep a clean historical time series
  filter(BRDYEAR >= 1997 & BRDYEAR <= 2024) %>%
  
  # Join metadata, dropping duplicate column names to keep it clean
  left_join(
    locations %>% select(-Watershed, -ParkCode, -Project), 
    by = "LocationID"
  )

# 3. SAVE THE CLEANED MASTER FILE ----------------------------------------------
# We save this as an RData file so it retains all our clean column types
save(clean_egg_data, file = "data/clean_egg_data.RData")
message("Success: Master data cleaned and saved to data/clean_egg_data.RData")

# 4. VISUALIZE THE BASELINE TREND ----------------------------------------------
yearly_summary <- clean_egg_data %>%
  group_by(BRDYEAR) %>%
  summarise(total_eggs = sum(NumberofEggMasses, na.rm = TRUE))

ggplot(yearly_summary, aes(x = BRDYEAR, y = total_eggs)) +
  geom_line(color = "forestgreen", linewidth = 1) +
  geom_point(color = "darkgreen", size = 2) +
  theme_minimal() +
  labs(
    title = "California Red-Legged Frog Egg Mass Trends (1997-2024)",
    subtitle = "Golden Gate National Recreation Area (GOGA)",
    x = "Breeding Year",
    y = "Total Egg Masses Counted"
  )
