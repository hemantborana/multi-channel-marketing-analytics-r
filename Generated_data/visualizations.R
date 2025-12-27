# comprehensive visualization suite


setwd("C:/Users/User/projects/S5/dmv-m8/Generated_data")

viz_folder <- "C:/Users/User/projects/S5/dmv-m8/Visualizations"
if (!dir.exists(viz_folder)) {
  dir.create(viz_folder)
}

cat("loading data for visualizations...\n")

campaigns <- read.csv("campaigns_cleaned.csv", stringsAsFactors = FALSE)
integrated <- read.csv("integrated_data.csv", stringsAsFactors = FALSE)
channel_perf <- read.csv("channel_performance.csv", stringsAsFactors = FALSE)
attribution <- read.csv("attribution_analysis.csv", stringsAsFactors = FALSE)
user_journeys <- read.csv("user_journeys.csv", stringsAsFactors = FALSE)
journey_clean <- read.csv("journey_cleaned.csv", stringsAsFactors = FALSE)

cat("creating visualizations...\n\n")

# viz 1: channel performance comparison
cat("creating viz 1: channel performance...\n")

channel_long <- channel_perf %>%
  select(channel, avg_roas, avg_ctr, avg_conversion_rate) %>%
  pivot_longer(cols = -channel, names_to = "metric", values_to = "value") %>%
  mutate(
    metric = case_when(
      metric == "avg_roas" ~ "ROAS",
      metric == "avg_ctr" ~ "CTR (%)",
      metric == "avg_conversion_rate" ~ "Conv Rate (%)"
    )
  )

p1 <- ggplot(channel_long, aes(x = reorder(channel, -value), y = value, fill = metric)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  facet_wrap(~metric, scales = "free_y", ncol = 3) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(face = "bold", size = 14),
    strip.text = element_text(face = "bold")
  ) +
  labs(
    title = "Channel Performance Metrics Comparison",
    x = "Channel",
    y = "Value",
    fill = "Metric"
  ) +
  scale_fill_brewer(palette = "Set2")

ggsave(file.path(viz_folder, "viz1_channel_performance.png"), p1, width = 12, height = 6, dpi = 300)
cat("saved viz1_channel_performance.png\n")

# viz 2: campaign roas vs budget 
cat("creating viz 2: roas vs budget scatter...\n")

p2 <- plot_ly(campaigns, 
              x = ~budget, 
              y = ~roas,
              type = 'scatter',
              mode = 'markers',
              marker = list(size = ~conversions/5, 
                            color = ~conversions,
                            colorscale = 'Viridis',
                            showscale = TRUE,
                            colorbar = list(title = "Conversions")),
              text = ~paste("Campaign:", campaign_name,
                            "<br>Budget: $", budget,
                            "<br>ROAS:", round(roas, 2),
                            "<br>Conversions:", conversions),
              hoverinfo = 'text') %>%
  layout(title = "Campaign ROAS vs Budget (size = conversions)",
         xaxis = list(title = "Budget ($)"),
         yaxis = list(title = "ROAS"),
         hovermode = 'closest')

htmlwidgets::saveWidget(p2, file.path(viz_folder, "viz2_roas_budget.html"), selfcontained = TRUE)
cat("saved viz2_roas_budget.html\n")

# viz 3: attribution model comparison 
cat("creating viz 3: attribution comparison...\n")

attribution_long <- attribution %>%
  pivot_longer(cols = -campaign_id, names_to = "model", values_to = "revenue") %>%
  filter(revenue > 0)

p3 <- ggplot(attribution_long, aes(x = model, y = revenue, fill = campaign_id)) +
  geom_bar(stat = "identity", position = "stack") +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "right"
  ) +
  labs(
    title = "Revenue Attribution by Model",
    subtitle = "Comparing different attribution methodologies",
    x = "Attribution Model",
    y = "Attributed Revenue ($)",
    fill = "Campaign"
  ) +
  scale_fill_brewer(palette = "Set3") +
  scale_y_continuous(labels = dollar_format())

ggsave(file.path(viz_folder, "viz3_attribution_comparison.png"), p3, width = 10, height = 6, dpi = 300)
cat("saved viz3_attribution_comparison.png\n")

# viz 4: customer journey funnel 
cat("creating viz 4: conversion funnel...\n")

# create funnel data
funnel_data <- journey_clean %>%
  summarise(
    impressions = sum(event_type == "AD_IMPRESSION"),
    clicks = sum(event_type == "AD_CLICK"),
    site_visits = sum(event_type == "SITE_VISIT"),
    product_views = sum(event_type == "PRODUCT_VIEW"),
    cart_adds = sum(event_type == "ADD_TO_CART"),
    purchases = sum(event_type == "PURCHASE")
  ) %>%
  pivot_longer(everything(), names_to = "stage", values_to = "count") %>%
  mutate(
    stage = factor(stage, levels = c("impressions", "clicks", "site_visits", 
                                     "product_views", "cart_adds", "purchases")),
    percentage = (count / first(count)) * 100
  )

p4 <- ggplot(funnel_data, aes(x = stage, y = count, fill = stage)) +
  geom_bar(stat = "identity", width = 0.8) +
  geom_text(aes(label = paste0(count, "\n(", round(percentage, 1), "%)")), 
            vjust = -0.5, size = 3.5, fontface = "bold") +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.text.x = element_text(angle = 0),
    legend.position = "none"
  ) +
  labs(
    title = "Customer Journey Conversion Funnel",
    subtitle = "Drop-off at each stage of the journey",
    x = "Journey Stage",
    y = "Number of Events"
  ) +
  scale_fill_brewer(palette = "Blues") +
  scale_x_discrete(labels = c("Impressions", "Clicks", "Site Visits", 
                              "Product Views", "Cart Adds", "Purchases"))

ggsave(file.path(viz_folder, "viz4_conversion_funnel.png"), p4, width = 10, height = 6, dpi = 300)
cat("saved viz4_conversion_funnel.png\n")

# viz 5: campaign efficiency matrix 
cat("creating viz 5: campaign efficiency heatmap...\n")

# prepare efficiency data
efficiency_matrix <- integrated %>%
  filter(!is.na(total_sessions)) %>%
  select(campaign_id, ctr, conversion_rate, roas, bounce_rate, avg_engagement_rate) %>%
  mutate(
    bounce_rate = ifelse(is.na(bounce_rate), 50, bounce_rate),
    avg_engagement_rate = ifelse(is.na(avg_engagement_rate), 0, avg_engagement_rate)
  )

# normalize for heatmap
efficiency_normalized <- efficiency_matrix %>%
  mutate(across(-campaign_id, ~scale(.)))

efficiency_long <- efficiency_normalized %>%
  pivot_longer(cols = -campaign_id, names_to = "metric", values_to = "value")

p5 <- plot_ly(data = efficiency_long,
              x = ~metric,
              y = ~campaign_id,
              z = ~value,
              type = "heatmap",
              colorscale = "RdYlGn",
              text = ~paste("Campaign:", campaign_id,
                            "<br>Metric:", metric,
                            "<br>Z-score:", round(value, 2)),
              hoverinfo = "text") %>%
  layout(title = "Campaign Performance Heatmap (normalized)",
         xaxis = list(title = "Metrics"),
         yaxis = list(title = "Campaign"))

htmlwidgets::saveWidget(p5, file.path(viz_folder, "viz5_efficiency_heatmap.html"), selfcontained = TRUE)
cat("saved viz5_efficiency_heatmap.html\n")

# viz 6: user journey timeline
cat("creating viz 6: user journey timelines...\n")

# select converters only
converters <- user_journeys %>% 
  filter(converted == TRUE) %>% 
  pull(user_id)

journey_timeline <- journey_clean %>%
  filter(user_id %in% converters[1:3]) %>%
  mutate(timestamp = as.POSIXct(timestamp))

p6 <- ggplot(journey_timeline, aes(x = timestamp, y = user_id, color = event_type)) +
  geom_point(size = 4, alpha = 0.7) +
  geom_line(aes(group = user_id), color = "gray", alpha = 0.3) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "bottom"
  ) +
  labs(
    title = "Sample Customer Journey Timelines (Converters)",
    subtitle = "Touchpoint sequence leading to conversion",
    x = "Time",
    y = "User ID",
    color = "Event Type"
  ) +
  scale_color_brewer(palette = "Set1")

ggsave(file.path(viz_folder, "viz6_journey_timeline.png"), p6, width = 12, height = 6, dpi = 300)
cat("saved viz6_journey_timeline.png\n")

# viz 7: revenue by channel with budget overlay
cat("creating viz 7: revenue vs budget by channel...\n")

channel_summary <- campaigns %>%
  group_by(channel) %>%
  summarise(
    total_revenue = sum(revenue),
    total_budget = sum(budget)
  )

p7 <- ggplot(channel_summary, aes(x = reorder(channel, -total_revenue))) +
  geom_bar(aes(y = total_revenue, fill = "Revenue"), 
           stat = "identity", alpha = 0.7) +
  geom_line(aes(y = total_budget * 30, group = 1, color = "Budget"), 
            size = 1.5) +
  geom_point(aes(y = total_budget * 30, color = "Budget"), size = 3) +
  scale_y_continuous(
    name = "Revenue ($)",
    sec.axis = sec_axis(~./30, name = "Budget ($)")
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "top"
  ) +
  labs(
    title = "Revenue vs Budget by Channel",
    subtitle = "Bars show revenue, line shows budget invested",
    x = "Channel",
    fill = "",
    color = ""
  ) +
  scale_fill_manual(values = c("Revenue" = "#2E86AB")) +
  scale_color_manual(values = c("Budget" = "#A23B72"))

ggsave(file.path(viz_folder, "viz7_revenue_budget_channel.png"), p7, width = 10, height = 6, dpi = 300)
cat("saved viz7_revenue_budget_channel.png\n")

# viz 8: interactive campaign dashboard 
cat("creating viz 8: interactive campaign dashboard...\n")

dash_data <- campaigns %>%
  arrange(desc(revenue)) %>%
  head(10)

fig1 <- plot_ly(dash_data, x = ~campaign_name, y = ~clicks, 
                type = 'bar', name = 'Clicks',
                marker = list(color = '#3498db'))

fig2 <- plot_ly(dash_data, x = ~campaign_name, y = ~conversions, 
                type = 'bar', name = 'Conversions',
                marker = list(color = '#2ecc71'))

p8 <- subplot(fig1, fig2, nrows = 2, shareX = TRUE) %>%
  layout(title = "Campaign Performance Dashboard",
         showlegend = TRUE,
         xaxis = list(tickangle = -45))

htmlwidgets::saveWidget(p8, file.path(viz_folder, "viz8_campaign_dashboard.html"), selfcontained = TRUE)
cat("saved viz8_campaign_dashboard.html\n")

cat("\nall visualizations created successfully!\n")
cat("saved to:", viz_folder, "\n")
cat("generated 8 visualizations:\n")
cat("- 5 static ggplot2 charts (PNG)\n")
cat("- 3 interactive plotly charts (HTML)\n")