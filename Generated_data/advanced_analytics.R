# advanced analytics and attribution modeling

library(dplyr)
library(tidyr)

setwd("C:/Users/User/projects/S5/dmv-m8/Generated_data")

cat("loading cleaned data...\n")

integrated <- read.csv("integrated_data.csv", stringsAsFactors = FALSE)
user_journeys <- read.csv("user_journeys.csv", stringsAsFactors = FALSE)
journey_clean <- read.csv("journey_cleaned.csv", stringsAsFactors = FALSE)
campaigns <- read.csv("campaigns_cleaned.csv", stringsAsFactors = FALSE)

cat("data loaded\n\n")

# 1. MULTI-CHANNEL ATTRIBUTION ANALYSIS

cat("--- Multi-Channel Attribution Analysis ---\n\n")

# simple attribution models

first_touch <- user_journeys %>%
  filter(converted == TRUE) %>%
  group_by(first_campaign) %>%
  summarise(
    conversions = n(),
    revenue = sum(conversion_value)
  ) %>%
  rename(campaign_id = first_campaign) %>%
  mutate(model = "First Touch")

cat("First Touch Attribution:\n")
print(first_touch)
cat("\n")

last_touch <- user_journeys %>%
  filter(converted == TRUE) %>%
  group_by(last_campaign) %>%
  summarise(
    conversions = n(),
    revenue = sum(conversion_value)
  ) %>%
  rename(campaign_id = last_campaign) %>%
  mutate(model = "Last Touch")

cat("Last Touch Attribution:\n")
print(last_touch)
cat("\n")

# linear attribution - equal credit to all touchpoints
journey_data <- journey_clean %>%
  filter(!is.na(campaign_id))

linear_attribution <- journey_data %>%
  inner_join(user_journeys %>% select(user_id, converted, conversion_value), 
             by = "user_id") %>%
  filter(converted == TRUE) %>%
  group_by(user_id) %>%
  mutate(
    touchpoint_count = n(),
    attributed_value = conversion_value / touchpoint_count
  ) %>%
  ungroup() %>%
  group_by(campaign_id) %>%
  summarise(
    conversions = n_distinct(user_id),
    attributed_revenue = sum(attributed_value)
  ) %>%
  mutate(model = "Linear")

cat("Linear Attribution (equal credit):\n")
print(linear_attribution)
cat("\n")

time_decay <- journey_data %>%
  inner_join(user_journeys %>% select(user_id, converted, conversion_value, last_touch), 
             by = "user_id") %>%
  filter(converted == TRUE) %>%
  mutate(
    timestamp = as.POSIXct(timestamp),
    last_touch = as.POSIXct(last_touch),
    days_before_conversion = as.numeric(difftime(last_touch, timestamp, units = "days"))
  ) %>%
  group_by(user_id) %>%
  mutate(
    weight = exp(-days_before_conversion / 7),
    total_weight = sum(weight),
    attributed_value = (weight / total_weight) * conversion_value
  ) %>%
  ungroup() %>%
  group_by(campaign_id) %>%
  summarise(
    attributed_revenue = sum(attributed_value),
    conversions = n_distinct(user_id)
  ) %>%
  mutate(model = "Time Decay")

cat("Time Decay Attribution (recent touchpoints weighted higher):\n")
print(time_decay)
cat("\n")

# combine all attribution models for comparison
all_attributions <- bind_rows(
  first_touch %>% select(campaign_id, model, revenue),
  last_touch %>% select(campaign_id, model, revenue),
  linear_attribution %>% select(campaign_id, model, attributed_revenue) %>% 
    rename(revenue = attributed_revenue),
  time_decay %>% select(campaign_id, model, attributed_revenue) %>% 
    rename(revenue = attributed_revenue)
)

# reshape for comparison
attribution_comparison <- all_attributions %>%
  pivot_wider(names_from = model, values_from = revenue, values_fill = 0)

cat("Attribution Model Comparison by Campaign:\n")
print(attribution_comparison)
cat("\n\n")


cat("--- Customer Journey Analysis ---\n\n")

journey_stats <- user_journeys %>%
  summarise(
    avg_touchpoints = mean(total_touchpoints),
    avg_journey_days = mean(journey_length_days),
    conversion_rate = mean(converted) * 100,
    avg_converter_touchpoints = mean(total_touchpoints[converted == TRUE]),
    avg_nonconverter_touchpoints = mean(total_touchpoints[converted == FALSE])
  )

cat("Journey Statistics:\n")
cat("Average touchpoints per user:", round(journey_stats$avg_touchpoints, 2), "\n")
cat("Average journey length:", round(journey_stats$avg_journey_days, 2), "days\n")
cat("Conversion rate:", round(journey_stats$conversion_rate, 2), "%\n")
cat("Converters avg touchpoints:", round(journey_stats$avg_converter_touchpoints, 2), "\n")
cat("Non-converters avg touchpoints:", round(journey_stats$avg_nonconverter_touchpoints, 2), "\n\n")

# event sequence analysis
event_sequences <- journey_clean %>%
  arrange(user_id, timestamp) %>%
  group_by(user_id) %>%
  summarise(
    sequence = paste(event_type, collapse = " -> ")
  ) %>%
  inner_join(user_journeys %>% select(user_id, converted), by = "user_id")

cat("Sample customer journeys:\n")
print(head(event_sequences %>% filter(converted == TRUE), 3))
cat("\n")

# common path analysis 
conversion_paths <- journey_clean %>%
  inner_join(user_journeys %>% select(user_id, converted), by = "user_id") %>%
  filter(converted == TRUE) %>%
  count(event_type) %>%
  arrange(desc(n))

cat("Events in conversion paths:\n")
print(conversion_paths)
cat("\n")

# touchpoint effectiveness
touchpoint_analysis <- journey_clean %>%
  inner_join(user_journeys %>% select(user_id, converted), by = "user_id") %>%
  group_by(event_type) %>%
  summarise(
    total_occurrences = n(),
    in_conversion_paths = sum(converted),
    conversion_rate = mean(converted) * 100
  ) %>%
  arrange(desc(conversion_rate))

cat("Touchpoint Effectiveness:\n")
print(touchpoint_analysis)
cat("\n\n")


cat("--- Statistical Analysis ---\n\n")

# campaign performance correlation analysis

performance_data <- integrated %>%
  select(campaign_id, budget, impressions, clicks, conversions, revenue, 
         ctr, conversion_rate, total_posts, avg_engagement_rate,
         total_sessions, bounce_rate, touchpoints) %>%
  filter(!is.na(total_sessions))

# correlation with revenue
correlations <- cor(performance_data %>% select(-campaign_id), 
                    use = "pairwise.complete.obs")

revenue_cors <- correlations[, "revenue"]
revenue_cors <- sort(revenue_cors[names(revenue_cors) != "revenue"], decreasing = TRUE)

cat("Correlation with Revenue (strongest predictors):\n")
print(head(revenue_cors, 5))
cat("\n")

# linear regression model - predicting revenue
revenue_model <- lm(revenue ~ budget + clicks + conversion_rate + 
                      total_posts + total_sessions, 
                    data = performance_data)

cat("Revenue Prediction Model:\n")
print(summary(revenue_model))
cat("\n")

# channel performance analysis
channel_performance <- campaigns %>%
  group_by(channel) %>%
  summarise(
    campaigns = n(),
    total_budget = sum(budget),
    total_revenue = sum(revenue),
    avg_roas = mean(roas),
    avg_ctr = mean(ctr),
    avg_conversion_rate = mean(conversion_rate),
    total_conversions = sum(conversions)
  ) %>%
  arrange(desc(avg_roas))

cat("Channel Performance Summary:\n")
print(channel_performance)
cat("\n")

# efficiency analysis - which campaigns overperform/underperform
campaigns_efficiency <- campaigns %>%
  mutate(
    expected_conversions = median(conversions),
    efficiency = (conversions / expected_conversions) * 100,
    status = case_when(
      efficiency >= 120 ~ "Overperforming",
      efficiency <= 80 ~ "Underperforming",
      TRUE ~ "Normal"
    )
  ) %>%
  select(campaign_id, campaign_name, channel, conversions, efficiency, status, roas)

cat("Campaign Efficiency Analysis:\n")
print(campaigns_efficiency)
cat("\n")

# cart abandonment analysis
abandonment_rate <- mean(user_journeys$abandoned_cart) * 100
potential_revenue <- sum(journey_clean$cart_value, na.rm = TRUE)

cat("Cart Abandonment Insights:\n")
cat("Abandonment rate:", round(abandonment_rate, 2), "%\n")
cat("Potential lost revenue:", round(potential_revenue, 2), "\n")
cat("Recovery opportunity:", round(potential_revenue * 0.15, 2), 
    "(assuming 15% recovery rate)\n\n")

# save analytics results
write.csv(attribution_comparison, "attribution_analysis.csv", row.names = FALSE)
write.csv(channel_performance, "channel_performance.csv", row.names = FALSE)
write.csv(campaigns_efficiency, "campaign_efficiency.csv", row.names = FALSE)

cat("analytics results saved\n")
cat("advanced analytics complete!\n")