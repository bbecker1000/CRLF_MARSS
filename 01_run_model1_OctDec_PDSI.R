# ==============================================================================
# SCRIPT 01: MARSS Model 1 - Oct-Dec PDSI
# Purpose: Fit multivariate autoregressive state-space model with local climate 
#          effects (direct + 3-yr lag) using Oct-Dec PDSI, bootstrap 95% CIs,
#          export parameter summaries, and save a 4-panel faceted summary plot.
# ==============================================================================

library(MARSS)
library(ggplot2)

# ------------------------------------------------------------------------------
# 1. BUILD CUSTOM LOCAL 'C' MATRIX
# ------------------------------------------------------------------------------
site_names <- rownames(dat_matrix)
cov_names  <- rownames(cov_data)

# Initialize matrix filled with "zero" (off-target effects forced to 0)
C_mat <- matrix("zero", nrow = length(site_names), ncol = length(cov_names))
rownames(C_mat) <- site_names
colnames(C_mat) <- cov_names

# Region prefix to full watershed name map
region_map <- c(
  "LS" = "LAGUNA_SALADA",
  "MC" = "MILAGRA_CREEK",
  "RC" = "REDWOOD_CREEK",
  "RL" = "RODEO_LAGOON",
  "TV" = "TENNESSEE_VALLEY",
  "WG" = "WILKINS_GULCH"
)

# Map local climate covariates to respective site rows
for (site in site_names) {
  prefix <- substr(site, 1, 2)
  reg    <- region_map[prefix]
  
  idx_direct <- grep(paste0("^", reg, ".*(?<!lag3)$"), cov_names, perl = TRUE)
  idx_lag3   <- grep(paste0("^", reg, ".*lag3$"), cov_names, perl = TRUE)
  
  C_mat[site, idx_direct] <- paste0("C_", site, "_direct")
  C_mat[site, idx_lag3]   <- paste0("C_", site, "_lag3")
}

# ------------------------------------------------------------------------------
# 2. SPECIFY AND FIT MARSS MODEL 1
# ------------------------------------------------------------------------------
model_spec_m1 <- list(
  Z = "identity",
  R = "zero",                  
  B = "identity",              
  U = "unequal",               
  Q = "diagonal and unequal",  
  C = C_mat,                   
  c = cov_data                 
)

cat("\n--- Fitting MARSS Model 1 (Oct-Dec PDSI) ---\n")
fit_model1 <- MARSS(
  y       = dat_matrix, 
  model   = model_spec_m1, 
  method  = "kem", 
  control = list(maxit = 2000)
)

# ------------------------------------------------------------------------------
# 3. PARAMETRIC BOOTSTRAP FOR 95% CONFIDENCE INTERVALS
# ------------------------------------------------------------------------------
cat("\n--- Bootstrapping 95% Confidence Intervals ---\n")
fit_model1_boot <- MARSSparamCIs(fit_model1, method = "parametric", nboot = 100)

# Extract parameter estimates and CIs
ests <- coef(fit_model1_boot, type = "vector")
lows <- coef(fit_model1_boot, type = "vector", what = "par.lowCI")
ups  <- coef(fit_model1_boot, type = "vector", what = "par.upCI")

params_m1 <- data.frame(
  Parameter = names(ests),
  Estimate  = round(ests, 4),
  Lower_95  = round(lows, 4),
  Upper_95  = round(ups, 4),
  stringsAsFactors = FALSE
)
rownames(params_m1) <- NULL

params_m1$Significance <- ifelse(
  params_m1$Lower_95 > 0, "Positive",
  ifelse(params_m1$Upper_95 < 0, "Negative", "Overlaps Zero")
)

# Separate parameter groups
U_params <- subset(params_m1, grepl("^U", Parameter))
Q_params <- subset(params_m1, grepl("^Q", Parameter))
C_params <- subset(params_m1, grepl("^C", Parameter) & !grepl("C.zero", Parameter))

# Export results to CSV
write.csv(params_m1, "MARSS_Model1_Bootstrapped_Parameters.csv", row.names = FALSE)

# ------------------------------------------------------------------------------
# 4. GENERATE FACETED SUMMARY PLOT
# ------------------------------------------------------------------------------
U_df <- U_params
U_df$Site  <- gsub("U.X.", "", U_df$Parameter)
U_df$Panel <- "1. Population Growth (U)"

Q_df <- Q_params
Q_df$Site  <- gsub("Q\\.\\(X\\.|,X.*", "", Q_df$Parameter)
Q_df$Panel <- "2. Process Variance (Q)"

C_dir_df <- subset(C_params, grepl("direct", Parameter))
C_dir_df$Site  <- sub("_direct", "", sub("C\\.C_", "", C_dir_df$Parameter))
C_dir_df$Panel <- "3. Direct Climate Effect (C)"

C_lag_df <- subset(C_params, grepl("lag3", Parameter))
C_lag_df$Site  <- sub("_lag3", "", sub("C\\.C_", "", C_lag_df$Parameter))
C_lag_df$Panel <- "4. 3-Yr Lag Climate Effect (C)"

plot_faceted_m1 <- rbind(
  U_df[, c("Site", "Estimate", "Lower_95", "Upper_95", "Panel")],
  Q_df[, c("Site", "Estimate", "Lower_95", "Upper_95", "Panel")],
  C_dir_df[, c("Site", "Estimate", "Lower_95", "Upper_95", "Panel")],
  C_lag_df[, c("Site", "Estimate", "Lower_95", "Upper_95", "Panel")]
)

plot_faceted_m1$Panel <- factor(
  plot_faceted_m1$Panel, 
  levels = c(
    "1. Population Growth (U)", 
    "2. Process Variance (Q)", 
    "3. Direct Climate Effect (C)", 
    "4. 3-Yr Lag Climate Effect (C)"
  )
)

fig_model1 <- ggplot(plot_faceted_m1, aes(x = Site, y = Estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40", alpha = 0.7) +
  geom_pointrange(aes(ymin = Lower_95, ymax = Upper_95, color = Panel), size = 0.6) +
  coord_flip() +
  facet_wrap(~ Panel, scales = "free_x", ncol = 4) +
  scale_color_manual(values = c(
    "1. Population Growth (U)"       = "#2B5C8F",
    "2. Process Variance (Q)"         = "#D95F02",
    "3. Direct Climate Effect (C)"    = "#1B9E77",
    "4. 3-Yr Lag Climate Effect (C)"  = "#7570B3"
  )) +
  labs(
    title = "MARSS Model 1 (Oct-Dec PDSI): Parameter Summary",
    subtitle = "Estimates ± 95% Parametric Bootstrap CIs (AICc: 1031.93)",
    x = "Monitoring Site",
    y = "Parameter Estimate"
  ) +
  theme_bw(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "none",
    strip.background = element_rect(fill = "gray92"),
    strip.text = element_text(face = "bold", size = 9)
  )

ggsave("Figure_Model1_Faceted_Summary.png", plot = fig_model1, width = 12, height = 6, dpi = 300)
cat("\nModel 1 Complete! Output saved to CSV and PNG.\n")