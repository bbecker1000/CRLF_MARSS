# ==============================================================================
# 10_make_figures.R
# CRLF MARSS PLUG-AND-PLAY PIPELINE
#
# PURPOSE:
#   Create standardized figures from registered MARSS model outputs.
#
# PRIMARY FIGURES:
#
#   1. Site-level parameter figure
#        U + Q + all site-specific C coefficients
#
#   2. Candidate-set AICc comparison figure
#
# IMPORTANT:
#   This module DOES NOT fit models.
#   This module DOES NOT bootstrap models.
#
# INPUTS EXPECTED:
#   parameter_result
#       output from 07_extract_results.R
#
#   fit_result
#       output from 05_fit_model.R or resumed fit from 11_run_registry.R
#
#   selection_result
#       output from 09_model_selection.R
#
#   site_registry
#       config/site_registry.csv loaded by 01_load_inputs.R
# ==============================================================================


library(ggplot2)
library(dplyr)
library(tibble)
library(readr)
library(stringr)


# ==============================================================================
# 1. DISPLAY LABELS FOR KNOWN FEATURES
#
# Unknown future features automatically fall back to their registry name.
# ==============================================================================

get_covariate_display_label <- function(
    covariate
) {
  
  label_lookup <- c(
    
    "PDSI_OctDec" =
      "Oct-Dec PDSI",
    
    "PDSI_JanMar" =
      "Jan-Mar PDSI",
    
    "PDSI_Interact" =
      "Oct-Dec × Jan-Mar",
    
    "PDSI_OctDec_lag3" =
      "Oct-Dec PDSI (t-3)",
    
    "PDSI_JanMar_lag3" =
      "Jan-Mar PDSI (t-3)",
    
    "PDSI_Interact_lag3" =
      "Oct-Dec × Jan-Mar (t-3)",
    
    "PDSI_OctDec_RunMean1" =
      "Oct-Dec PDSI: t",
    
    "PDSI_OctDec_RunMean2" =
      "Oct-Dec PDSI: mean(t, t-1)",
    
    "PDSI_OctDec_RunMean3" =
      "Oct-Dec PDSI: mean(t, t-1, t-2)",
    
    "PDSI_JanMar_RunMean1" =
      "Jan-Mar PDSI: t",
    
    "PDSI_JanMar_RunMean2" =
      "Jan-Mar PDSI: mean(t, t-1)",
    
    "PDSI_JanMar_RunMean3" =
      "Jan-Mar PDSI: mean(t, t-1, t-2)"
  )
  
  
  if (
    length(covariate) == 0 ||
    is.na(covariate)
  ) {
    
    return(
      NA_character_
    )
  }
  
  
  if (
    covariate %in% names(label_lookup)
  ) {
    
    return(
      unname(
        label_lookup[covariate]
      )
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Future feature fallback
  # ---------------------------------------------------------------------------
  
  as.character(
    covariate
  )
}


# ==============================================================================
# 2. GET SITE DISPLAY ORDER
#
# Current site registry is ordered approximately:
#
#   LS01
#   LS04
#   ...
#   WG01
#
# ggplot displays the first factor level at the BOTTOM of a discrete y-axis.
# Therefore reversing the registry order puts LS01 at the TOP and WG01 at
# the BOTTOM, matching our desired figure orientation.
# ==============================================================================

get_plot_site_levels <- function(
    site_registry
) {
  
  active_sites <- site_registry %>%
    filter(
      Active
    ) %>%
    pull(
      Site_ID
    )
  
  
  rev(
    active_sites
  )
}


# ==============================================================================
# 3. BUILD PARAMETER PANEL LABEL
# ==============================================================================

get_parameter_panel <- function(
    parameter_type,
    covariate
) {
  
  if (
    parameter_type == "U"
  ) {
    
    return(
      "Population Growth / Drift (U)"
    )
  }
  
  
  if (
    parameter_type == "Q"
  ) {
    
    return(
      "Process Variance (Q)"
    )
  }
  
  
  if (
    parameter_type == "C"
  ) {
    
    cov_label <- get_covariate_display_label(
      covariate
    )
    
    
    return(
      paste0(
        "Climate: ",
        cov_label
      )
    )
  }
  
  
  NA_character_
}


# ==============================================================================
# 4. BUILD PARAMETER FIGURE CAPTION
#
# Null models should NOT claim that climate coefficients were estimated.
# ==============================================================================

build_parameter_figure_caption <- function(
    aicc,
    expected_C
) {
  
  if (
    expected_C > 0
  ) {
    
    return(
      paste0(
        "AICc = ",
        round(
          aicc,
          2
        ),
        ". Climate coefficients are estimated independently by pond."
      )
    )
  }
  
  
  paste0(
    "AICc = ",
    round(
      aicc,
      2
    ),
    ". Null model: no climate covariates included."
  )
}


# ==============================================================================
# 5. BUILD PARAMETER FIGURE SUBTITLE
# ==============================================================================

build_parameter_figure_subtitle <- function(
    model_family,
    n_boot
) {
  
  if (
    !is.na(
      n_boot
    )
  ) {
    
    return(
      paste0(
        model_family,
        " | Estimates ± 95% parametric bootstrap CIs (n = ",
        n_boot,
        ")"
      )
    )
  }
  
  
  model_family
}


# ==============================================================================
# 6. SITE-LEVEL PARAMETER FIGURE
# ==============================================================================

plot_registered_model_parameters <- function(
    parameter_result,
    fit_result,
    site_registry
) {
  
  model_id <- fit_result$model_id
  
  model_dir <- fit_result$model_dir
  
  
  cat("\n")
  cat("============================================================\n")
  cat("CREATING SITE-LEVEL PARAMETER FIGURE\n")
  cat("============================================================\n")
  
  cat(
    "Model:",
    model_id,
    "\n"
  )
  
  
  # ===========================================================================
  # INPUT TABLE
  # ===========================================================================
  
  df_all <- parameter_result$parameter_table
  
  
  if (
    is.null(df_all) ||
    nrow(df_all) == 0
  ) {
    
    stop(
      paste(
        "No parameter table available for:",
        model_id
      )
    )
  }
  
  
  # ===========================================================================
  # REQUIRED FIELDS
  # ===========================================================================
  
  required_fields <- c(
    
    "Site_ID",
    
    "Parameter_Type",
    
    "Covariate",
    
    "Estimate",
    
    "Lower_95",
    
    "Upper_95",
    
    "CI_Excludes_Zero",
    
    "N_Boot"
  )
  
  
  missing_fields <- setdiff(
    required_fields,
    names(
      df_all
    )
  )
  
  
  if (
    length(
      missing_fields
    ) > 0
  ) {
    
    stop(
      paste(
        "Parameter table is missing required fields:",
        paste(
          missing_fields,
          collapse = ", "
        )
      )
    )
  }
  
  
  # ===========================================================================
  # FIGURE USES U, Q, AND C
  #
  # x0 remains preserved in parameters.csv but is intentionally omitted from
  # the primary ecological parameter figure.
  # ===========================================================================
  
  df_plot <- df_all %>%
    
    filter(
      Parameter_Type %in%
        c(
          "U",
          "Q",
          "C"
        )
    )
  
  
  if (
    nrow(
      df_plot
    ) == 0
  ) {
    
    stop(
      paste(
        "No U, Q, or C parameters available for:",
        model_id
      )
    )
  }
  
  
  # ===========================================================================
  # SITE ORDER
  # ===========================================================================
  
  site_levels <- get_plot_site_levels(
    site_registry
  )
  
  
  df_plot <- df_plot %>%
    
    mutate(
      
      Site_ID =
        factor(
          Site_ID,
          levels = site_levels
        )
    )
  
  
  # ---------------------------------------------------------------------------
  # Every plotted parameter must resolve to a registered site
  # ---------------------------------------------------------------------------
  
  if (
    anyNA(
      df_plot$Site_ID
    )
  ) {
    
    bad_parameters <- df_plot %>%
      filter(
        is.na(
          Site_ID
        )
      )
    
    
    print(
      bad_parameters,
      n = Inf
    )
    
    
    stop(
      paste(
        "Figure construction failed:",
        "one or more U/Q/C parameters could not be mapped to a registered site."
      )
    )
  }
  
  
  # ===========================================================================
  # PANEL LABELS
  # ===========================================================================
  
  df_plot <- df_plot %>%
    
    rowwise() %>%
    
    mutate(
      
      Panel =
        get_parameter_panel(
          Parameter_Type,
          Covariate
        )
    ) %>%
    
    ungroup()
  
  
  if (
    anyNA(
      df_plot$Panel
    )
  ) {
    
    stop(
      paste(
        "Figure construction failed:",
        "at least one U/Q/C parameter could not be assigned to a panel."
      )
    )
  }
  
  
  # ===========================================================================
  # PANEL ORDER
  #
  # U first
  # Q second
  # Then climate covariates in the exact order requested by the registry.
  # ===========================================================================
  
  requested_covariates <-
    fit_result$registered_spec$covariates
  
  
  climate_panels <- character(
    0
  )
  
  
  if (
    length(
      requested_covariates
    ) > 0
  ) {
    
    climate_panels <- vapply(
      
      requested_covariates,
      
      function(x) {
        
        paste0(
          "Climate: ",
          get_covariate_display_label(
            x
          )
        )
      },
      
      character(
        1
      )
    )
  }
  
  
  panel_order <- c(
    
    "Population Growth / Drift (U)",
    
    "Process Variance (Q)",
    
    climate_panels
  )
  
  
  # ---------------------------------------------------------------------------
  # Protect future valid features not currently included in display dictionary
  # ---------------------------------------------------------------------------
  
  unexpected_panels <- setdiff(
    unique(
      df_plot$Panel
    ),
    panel_order
  )
  
  
  panel_order <- c(
    panel_order,
    unexpected_panels
  )
  
  
  panel_order <- unique(
    panel_order
  )
  
  
  df_plot$Panel <- factor(
    df_plot$Panel,
    levels = panel_order
  )
  
  
  # ===========================================================================
  # FIGURE QA
  # ===========================================================================
  
  n_sites <- sum(
    site_registry$Active
  )
  
  
  n_U <- sum(
    df_plot$Parameter_Type == "U"
  )
  
  
  n_Q <- sum(
    df_plot$Parameter_Type == "Q"
  )
  
  
  n_C <- sum(
    df_plot$Parameter_Type == "C"
  )
  
  
  expected_C <-
    fit_result$registered_spec$expected_free_C
  
  
  cat("\n")
  cat("------------------------------------------------------------\n")
  cat("PARAMETER FIGURE QA\n")
  cat("------------------------------------------------------------\n")
  
  
  cat(
    "Active sites:",
    n_sites,
    "\n"
  )
  
  
  cat(
    "U parameters:",
    n_U,
    "(expected",
    n_sites,
    ")\n"
  )
  
  
  cat(
    "Q parameters:",
    n_Q,
    "(expected",
    n_sites,
    ")\n"
  )
  
  
  cat(
    "C parameters:",
    n_C,
    "(expected",
    expected_C,
    ")\n"
  )
  
  
  # ---------------------------------------------------------------------------
  # Hard QA gates
  # ---------------------------------------------------------------------------
  
  if (
    n_U != n_sites
  ) {
    
    stop(
      paste(
        "Figure QA failed:",
        model_id,
        "expected",
        n_sites,
        "U parameters but found",
        n_U
      )
    )
  }
  
  
  if (
    n_Q != n_sites
  ) {
    
    stop(
      paste(
        "Figure QA failed:",
        model_id,
        "expected",
        n_sites,
        "Q parameters but found",
        n_Q
      )
    )
  }
  
  
  if (
    n_C != expected_C
  ) {
    
    stop(
      paste(
        "Figure QA failed:",
        model_id,
        "expected",
        expected_C,
        "C parameters but found",
        n_C
      )
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Every U site must occur exactly once
  # ---------------------------------------------------------------------------
  
  U_site_qa <- df_plot %>%
    
    filter(
      Parameter_Type == "U"
    ) %>%
    
    count(
      Site_ID
    ) %>%
    
    filter(
      n != 1
    )
  
  
  if (
    nrow(
      U_site_qa
    ) > 0
  ) {
    
    print(
      U_site_qa,
      n = Inf
    )
    
    stop(
      "Figure QA failed: U parameters are not exactly one per site."
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # Every Q site must occur exactly once
  # ---------------------------------------------------------------------------
  
  Q_site_qa <- df_plot %>%
    
    filter(
      Parameter_Type == "Q"
    ) %>%
    
    count(
      Site_ID
    ) %>%
    
    filter(
      n != 1
    )
  
  
  if (
    nrow(
      Q_site_qa
    ) > 0
  ) {
    
    print(
      Q_site_qa,
      n = Inf
    )
    
    stop(
      "Figure QA failed: Q parameters are not exactly one per site."
    )
  }
  
  
  # ---------------------------------------------------------------------------
  # For climate models, each requested covariate should occur once per site
  # ---------------------------------------------------------------------------
  
  if (
    expected_C > 0
  ) {
    
    C_site_cov_qa <- df_plot %>%
      
      filter(
        Parameter_Type == "C"
      ) %>%
      
      count(
        Site_ID,
        Covariate
      ) %>%
      
      filter(
        n != 1
      )
    
    
    if (
      nrow(
        C_site_cov_qa
      ) > 0
    ) {
      
      print(
        C_site_cov_qa,
        n = Inf
      )
      
      stop(
        paste(
          "Figure QA failed:",
          "site-specific C coefficients are not exactly one per site-covariate combination."
        )
      )
    }
  }
  
  
  cat(
    "Parameter figure QA PASS.\n"
  )
  
  
  # ===========================================================================
  # MODEL METADATA
  # ===========================================================================
  
  aicc <- fit_result$fit_summary$AICc[[1]]
  
  
  n_boot_values <- unique(
    df_plot$N_Boot[
      !is.na(
        df_plot$N_Boot
      )
    ]
  )
  
  
  if (
    length(
      n_boot_values
    ) == 1
  ) {
    
    n_boot <- as.integer(
      n_boot_values[[1]]
    )
    
  } else {
    
    n_boot <- NA_integer_
  }
  
  
  figure_subtitle <- build_parameter_figure_subtitle(
    
    model_family =
      fit_result$registered_spec$model_family,
    
    n_boot =
      n_boot
  )
  
  
  figure_caption <- build_parameter_figure_caption(
    
    aicc =
      aicc,
    
    expected_C =
      expected_C
  )
  
  
  # ===========================================================================
  # FIGURE
  # ===========================================================================
  
  p <- ggplot(
    
    df_plot,
    
    aes(
      x = Estimate,
      y = Site_ID
    )
  ) +
    
    geom_vline(
      xintercept = 0,
      linetype = "dashed",
      linewidth = 0.55
    ) +
    
    geom_errorbar(
      aes(
        xmin = Lower_95,
        xmax = Upper_95
      ),
      width = 0,
      linewidth = 0.65
    ) +
    
    geom_point(
      aes(
        shape = CI_Excludes_Zero
      ),
      size = 2.7
    ) +
    
    facet_wrap(
      ~ Panel,
      scales = "free_x",
      nrow = 1,
      labeller = label_wrap_gen(
        width = 24
      )
    ) +
    
    scale_y_discrete(
      drop = FALSE
    ) +
    
    scale_shape_manual(
      
      values = c(
        `FALSE` = 16,
        `TRUE` = 17
      ),
      
      labels = c(
        `FALSE` = "95% CI overlaps zero",
        `TRUE` = "95% CI excludes zero"
      ),
      
      name = NULL,
      
      na.translate = FALSE
    ) +
    
    labs(
      
      title =
        paste0(
          "MARSS ",
          model_id,
          ": Site-Specific Parameter Estimates"
        ),
      
      subtitle =
        figure_subtitle,
      
      x =
        "Parameter Estimate",
      
      y =
        "Monitoring Pond",
      
      caption =
        figure_caption
    ) +
    
    theme_bw(
      base_size = 11
    ) +
    
    theme(
      
      plot.title =
        element_text(
          face = "bold",
          size = 14
        ),
      
      plot.subtitle =
        element_text(
          size = 10
        ),
      
      plot.caption =
        element_text(
          size = 9
        ),
      
      strip.text =
        element_text(
          face = "bold",
          size = 9
        ),
      
      axis.text.y =
        element_text(
          size = 9
        ),
      
      panel.grid.minor =
        element_blank(),
      
      panel.grid.major.y =
        element_line(
          linewidth = 0.25
        ),
      
      legend.position =
        "bottom"
    )
  
  
  # ===========================================================================
  # SAVE FIGURE
  # ===========================================================================
  
  figure_dir <- file.path(
    model_dir,
    "figures"
  )
  
  
  dir.create(
    figure_dir,
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  
  n_panels <- length(
    panel_order
  )
  
  
  fig_width <- max(
    9,
    min(
      24,
      n_panels * 3.5
    )
  )
  
  
  figure_path <- file.path(
    
    figure_dir,
    
    paste0(
      "SITELEVEL_",
      model_id,
      "_All_Parameters.png"
    )
  )
  
  
  ggsave(
    
    filename =
      figure_path,
    
    plot =
      p,
    
    width =
      fig_width,
    
    height =
      7.5,
    
    dpi =
      300
  )
  
  
  # ===========================================================================
  # SAVE EXACT DATA USED TO MAKE FIGURE
  # ===========================================================================
  
  figure_data_path <- file.path(
    
    figure_dir,
    
    paste0(
      "SITELEVEL_",
      model_id,
      "_Figure_Data.csv"
    )
  )
  
  
  figure_data_to_save <- df_plot %>%
    
    mutate(
      
      Site_ID =
        as.character(
          Site_ID
        ),
      
      Panel =
        as.character(
          Panel
        )
    )
  
  
  write_csv(
    figure_data_to_save,
    figure_data_path
  )
  
  
  # ===========================================================================
  # REPORT
  # ===========================================================================
  
  cat("\n")
  cat("------------------------------------------------------------\n")
  cat("PARAMETER FIGURE SAVED\n")
  cat("------------------------------------------------------------\n")
  
  
  cat(
    figure_path,
    "\n"
  )
  
  
  cat(
    "Figure data:",
    figure_data_path,
    "\n"
  )
  
  
  # ===========================================================================
  # RETURN
  # ===========================================================================
  
  list(
    
    model_id =
      model_id,
    
    plot =
      p,
    
    figure_data =
      df_plot,
    
    figure_path =
      figure_path,
    
    figure_data_path =
      figure_data_path
  )
}


# ==============================================================================
# 7. CANDIDATE-SET AICc FIGURE
#
# A figure is made only when at least TWO converged models exist in the
# candidate set.
# ==============================================================================

plot_candidate_set_aicc <- function(
    selection_result,
    project_root
) {
  
  cat("\n")
  cat("============================================================\n")
  cat("CREATING CANDIDATE-SET AICc FIGURES\n")
  cat("============================================================\n")
  
  
  # ===========================================================================
  # INPUT
  # ===========================================================================
  
  selection_table <-
    selection_result$model_selection
  
  
  if (
    is.null(
      selection_table
    ) ||
    nrow(
      selection_table
    ) == 0
  ) {
    
    cat(
      "No model-selection table is available for plotting.\n"
    )
    
    
    return(
      invisible(
        list()
      )
    )
  }
  
  
  # ===========================================================================
  # REQUIRED FIELDS
  # ===========================================================================
  
  required_fields <- c(
    
    "Candidate_Set",
    
    "Model_ID",
    
    "Fit_Status",
    
    "AICc",
    
    "Delta_AICc",
    
    "Weight_AICc"
  )
  
  
  missing_fields <- setdiff(
    required_fields,
    names(
      selection_table
    )
  )
  
  
  if (
    length(
      missing_fields
    ) > 0
  ) {
    
    stop(
      paste(
        "Model-selection table is missing required fields:",
        paste(
          missing_fields,
          collapse = ", "
        )
      )
    )
  }
  
  
  # ===========================================================================
  # KEEP ONLY CONVERGED MODELS WITH VALID AICc RESULTS
  # ===========================================================================
  
  eligible <- selection_table %>%
    
    filter(
      
      Fit_Status == "CONVERGED",
      
      is.finite(
        AICc
      ),
      
      is.finite(
        Delta_AICc
      )
    )
  
  
  candidate_sets <- unique(
    eligible$Candidate_Set
  )
  
  
  if (
    length(
      candidate_sets
    ) == 0
  ) {
    
    cat(
      "No completed candidate sets are available for AICc plotting.\n"
    )
    
    
    return(
      invisible(
        list()
      )
    )
  }
  
  
  # ===========================================================================
  # OUTPUT DIRECTORY
  # ===========================================================================
  
  output_dir <- file.path(
    project_root,
    "marss_results",
    "plots"
  )
  
  
  dir.create(
    output_dir,
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  
  plots <- list()
  
  
  # ===========================================================================
  # LOOP THROUGH CANDIDATE SETS
  # ===========================================================================
  
  for (
    candidate_name in
    candidate_sets
  ) {
    
    df <- eligible %>%
      
      filter(
        Candidate_Set ==
          candidate_name
      ) %>%
      
      arrange(
        Delta_AICc
      )
    
    
    # -------------------------------------------------------------------------
    # Require at least two models for an actual model comparison.
    # -------------------------------------------------------------------------
    
    if (
      nrow(
        df
      ) < 2
    ) {
      
      cat(
        "Skipping AICc figure for",
        candidate_name,
        "- only",
        nrow(df),
        "converged model is currently fitted.\n"
      )
      
      
      next
    }
    
    
    # -------------------------------------------------------------------------
    # Preserve ranking.
    #
    # Best model is first in df.
    # Reversing levels causes best model to appear at TOP of ggplot y-axis.
    # -------------------------------------------------------------------------
    
    ordered_models <- as.character(
      df$Model_ID
    )
    
    
    df <- df %>%
      
      mutate(
        
        Model_ID =
          factor(
            Model_ID,
            levels =
              rev(
                ordered_models
              )
          )
      )
    
    
    # =========================================================================
    # BUILD AICc FIGURE
    # =========================================================================
    
    p <- ggplot(
      
      df,
      
      aes(
        x = Delta_AICc,
        y = Model_ID
      )
    ) +
      
      geom_vline(
        xintercept = 0,
        linetype = "dashed",
        linewidth = 0.5
      ) +
      
      geom_segment(
        
        aes(
          x = 0,
          xend = Delta_AICc,
          y = Model_ID,
          yend = Model_ID
        ),
        
        linewidth = 0.7
      ) +
      
      geom_point(
        size = 3
      ) +
      
      geom_text(
        
        aes(
          label =
            paste0(
              "Delta AICc = ",
              round(
                Delta_AICc,
                2
              )
            )
        ),
        
        hjust = -0.1,
        
        size = 3.5
      ) +
      
      labs(
        
        title =
          paste0(
            "MARSS Candidate Model Comparison: ",
            candidate_name
          ),
        
        subtitle =
          "Models ranked by small-sample corrected Akaike Information Criterion",
        
        x =
          expression(
            Delta * AIC[c]
          ),
        
        y =
          "Registered Model"
      ) +
      
      theme_bw(
        base_size = 11
      ) +
      
      theme(
        
        plot.title =
          element_text(
            face = "bold"
          ),
        
        panel.grid.minor =
          element_blank()
      )
    
    
    # =========================================================================
    # PROVIDE ROOM FOR TEXT LABELS
    # =========================================================================
    
    max_delta <- max(
      df$Delta_AICc,
      na.rm = TRUE
    )
    
    
    if (
      is.finite(
        max_delta
      ) &&
      max_delta > 0
    ) {
      
      p <- p +
        
        expand_limits(
          x =
            max_delta *
            1.20
        )
      
    } else {
      
      # -----------------------------------------------------------------------
      # Protect case where two models have identical AICc.
      # -----------------------------------------------------------------------
      
      p <- p +
        
        expand_limits(
          x = 1
        )
    }
    
    
    # =========================================================================
    # SAFE FILE NAME
    # =========================================================================
    
    safe_candidate_name <- str_replace_all(
      
      candidate_name,
      
      "[^A-Za-z0-9]+",
      
      "_"
    )
    
    
    figure_path <- file.path(
      
      output_dir,
      
      paste0(
        "MODEL_SELECTION_",
        safe_candidate_name,
        "_DeltaAICc.png"
      )
    )
    
    
    figure_data_path <- file.path(
      
      output_dir,
      
      paste0(
        "MODEL_SELECTION_",
        safe_candidate_name,
        "_Data.csv"
      )
    )
    
    
    # =========================================================================
    # SAVE
    # =========================================================================
    
    ggsave(
      
      filename =
        figure_path,
      
      plot =
        p,
      
      width =
        9,
      
      height =
        max(
          4.5,
          nrow(df) *
            0.55
        ),
      
      dpi =
        300
    )
    
    
    # -------------------------------------------------------------------------
    # Save exact model-selection data used for figure
    # -------------------------------------------------------------------------
    
    figure_data_to_save <- df %>%
      
      mutate(
        Model_ID =
          as.character(
            Model_ID
          )
      )
    
    
    write_csv(
      figure_data_to_save,
      figure_data_path
    )
    
    
    # =========================================================================
    # STORE PLOT RESULT
    #
    # IMPORTANT:
    # Keep double-bracket indexing together.
    # =========================================================================
    
    plots[[candidate_name]] <- list(
      
      plot =
        p,
      
      path =
        figure_path,
      
      data_path =
        figure_data_path
    )
    
    
    cat(
      "Saved AICc figure:",
      figure_path,
      "\n"
    )
    
    
    cat(
      "Saved AICc figure data:",
      figure_data_path,
      "\n"
    )
  }
  
  
  invisible(
    plots
  )
}


# ==============================================================================
# MODULE LOAD MESSAGE
# ==============================================================================

cat("\n============================================================\n")
cat("10_make_figures.R LOADED SUCCESSFULLY\n")
cat("============================================================\n")