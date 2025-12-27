# ETL Pipeline for Multi-Source Marketing Data

library(jsonlite)
library(XML)
library(dplyr)
library(tidyr)
library(lubridate)

setwd("C:/Users/User/projects/S5/dmv-m8/Generated_data")

cat("starting ETL pipeline...\n\n")

# EXTRACT phase - load all raw data

cat("extracting data from sources...\n")

# source 1: CSV
campaigns_raw <- read.csv("Digital_Campaigns.csv", stringsAsFactors = FALSE)

# source 2: JSON
social_raw <- fromJSON("Social_Engagement.json", simplifyDataFrame = TRUE)

# source 3: XML
xml_doc <- xmlParse("Web_Analytics.xml")
xml_root <- xmlRoot(xml_doc)

web_sessions <- xmlApply(xml_root, function(x) {
  data.frame(
    session_id = xmlValue(x[["session_id"]]),
    date = xmlValue(x[["date"]]),
    source = xmlValue(x[["source"]]),
    medium = xmlValue(x[["medium"]]),
    campaign = xmlValue(x[["campaign"]]),
    pageviews = as.numeric(xmlValue(x[["pageviews"]])),
    duration = as.numeric(xmlValue(x[["duration_seconds"]])),
    bounce = xmlValue(x[["bounce"]]),
    transactions = as.numeric(xmlValue(x[["transactions"]])),
    revenue = as.numeric(xmlValue(x[["revenue"]])),
    device = xmlValue(x[["device"]]),
    stringsAsFactors = FALSE
  )
})
web_raw <- do.call(rbind, web_sessions)

# source 4: TXT
journey_raw <- readLines("Customer_Journey.txt")
journey_lines <- journey_raw[journey_raw != ""]

cat("extraction complete\n\n")

# TRANSFORM phase - clean and standardize

cat("transforming data...\n")

campaigns_clean <- campaigns_raw %>%
  mutate(
    start_date = as.Date(start_date),
    end_date = as.Date(end_date),
    campaign_duration = as.numeric(end_date - start_date)
  )

campaigns_clean <- campaigns_clean %>%
  mutate(
    cost_per_conversion = round(budget / conversions, 2),
    revenue_per_conversion = round(revenue / conversions, 2)
  )

cat("campaigns data cleaned:", nrow(campaigns_clean), "records\n")

# transform social data
social_clean <- social_raw %>%
  mutate(
    post_date = as.POSIXct(post_date, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"),
    post_date_only = as.Date(post_date),
    saves = ifelse(is.na(saves), 0, saves),
    total_engagement = likes + comments + shares + saves
  )

social_clean <- social_clean %>%
  left_join(campaigns_clean %>% select(campaign_id, channel), by = "campaign_id")

cat("social data cleaned:", nrow(social_clean), "records\n")

# transform web analytics
web_clean <- web_raw %>%
  mutate(
    date = as.Date(date),
    bounce = as.logical(ifelse(bounce == "true", TRUE, FALSE)),
    # standardize campaign names
    campaign = ifelse(campaign == "none", NA, campaign),
    duration_minutes = round(duration / 60, 2)
  )

# classify traffic type
web_clean <- web_clean %>%
  mutate(
    traffic_type = case_when(
      source %in% c("Direct", "Organic") ~ "Organic",
      source %in% c("Email") ~ "Email",
      source %in% c("Facebook", "Instagram", "Twitter", "LinkedIn") ~ "Social",
      source %in% c("Google Ads") ~ "Paid Search",
      source %in% c("Display", "YouTube") ~ "Display/Video",
      TRUE ~ "Other"
    )
  )

cat("web analytics cleaned:", nrow(web_clean), "records\n")

parse_journey <- function(line) {
  parts <- strsplit(line, " \\| ")[[1]]
  if(length(parts) >= 4) {
    timestamp_parts <- strsplit(parts[1], " ")[[1]]
    date_parts <- strsplit(timestamp_parts[1], "-")[[1]]
    
    correct_date <- paste0("2024-", date_parts[2], "-", date_parts[3])
    correct_timestamp <- paste(correct_date, timestamp_parts[2])
    
    return(data.frame(
      timestamp = correct_timestamp,
      user_id = parts[2],
      event_type = parts[3],
      campaign_id = parts[4],
      details = ifelse(length(parts) > 4, parts[5], ""),
      stringsAsFactors = FALSE
    ))
  }
  return(NULL)
}

journey_parsed <- do.call(rbind, lapply(journey_lines, parse_journey))

journey_clean <- journey_parsed %>%
  mutate(
    timestamp = as.POSIXct(timestamp, format = "%Y-%m-%d %H:%M:%S"),
    date = as.Date(timestamp),
    campaign_id = ifelse(campaign_id == "none", NA, campaign_id)
  )

# extract order values from purchase events
journey_clean <- journey_clean %>%
  mutate(
    order_value = ifelse(
      event_type == "PURCHASE",
      as.numeric(gsub(".*order_value=([0-9.]+).*", "\\1", details)),
      NA
    ),
    cart_value = ifelse(
      event_type == "CART_ABANDON",
      as.numeric(gsub(".*cart_value=([0-9.]+).*", "\\1", details)),
      NA
    )
  )

cat("customer journey cleaned:", nrow(journey_clean), "records\n")

cat("\ntransformation complete\n\n")

# LOAD phase - create integrated datasets

cat("creating integrated datasets...\n")

# dataset 1: campaign performance with social engagement
campaign_social <- campaigns_clean %>%
  left_join(
    social_clean %>%
      group_by(campaign_id) %>%
      summarise(
        total_posts = n(),
        total_social_likes = sum(likes),
        total_social_comments = sum(comments),
        total_social_shares = sum(shares),
        total_social_clicks = sum(clicks),
        avg_engagement_rate = mean(engagement_rate)
      ),
    by = "campaign_id"
  ) %>%
  mutate(
    total_posts = ifelse(is.na(total_posts), 0, total_posts),
    total_social_likes = ifelse(is.na(total_social_likes), 0, total_social_likes)
  )

cat("campaign + social integration:", nrow(campaign_social), "campaigns\n")

# dataset 2: web traffic by campaign
web_by_campaign <- web_clean %>%
  filter(!is.na(campaign)) %>%
  group_by(campaign) %>%
  summarise(
    total_sessions = n(),
    total_pageviews = sum(pageviews),
    avg_duration = mean(duration_minutes),
    bounce_rate = mean(bounce) * 100,
    web_transactions = sum(transactions),
    web_revenue = sum(revenue),
    mobile_sessions = sum(device == "mobile"),
    desktop_sessions = sum(device == "desktop")
  )

campaign_web <- campaign_social %>%
  left_join(web_by_campaign, by = c("campaign_id" = "campaign"))

cat("campaign + web integration:", nrow(campaign_web), "campaigns\n")

journey_by_campaign <- journey_clean %>%
  filter(!is.na(campaign_id)) %>%
  group_by(campaign_id) %>%
  summarise(
    touchpoints = n(),
    unique_users = n_distinct(user_id),
    ad_impressions = sum(event_type == "AD_IMPRESSION"),
    ad_clicks = sum(event_type == "AD_CLICK"),
    site_visits = sum(event_type == "SITE_VISIT"),
    purchases = sum(event_type == "PURCHASE"),
    cart_abandons = sum(event_type == "CART_ABANDON"),
    journey_revenue = sum(order_value, na.rm = TRUE)
  )

# final integrated dataset
integrated_data <- campaign_web %>%
  left_join(journey_by_campaign, by = "campaign_id")

cat("final integrated dataset:", nrow(integrated_data), "campaigns\n")

# dataset 4: user-level journey analysis
user_journeys <- journey_clean %>%
  arrange(user_id, timestamp) %>%
  group_by(user_id) %>%
  summarise(
    first_touch = min(timestamp),
    last_touch = max(timestamp),
    journey_length_days = as.numeric(difftime(max(timestamp), min(timestamp), units = "days")),
    total_touchpoints = n(),
    first_campaign = first(campaign_id[!is.na(campaign_id)]),
    last_campaign = last(campaign_id[!is.na(campaign_id)]),
    converted = any(event_type == "PURCHASE"),
    conversion_value = sum(order_value, na.rm = TRUE),
    abandoned_cart = any(event_type == "CART_ABANDON")
  )

cat("user journey analysis:", nrow(user_journeys), "users\n")

cat("\nintegration complete\n\n")

# data quality validation
cat("data quality checks:\n")
cat("- campaigns with complete data:", 
    sum(!is.na(integrated_data$total_sessions)), "out of", nrow(integrated_data), "\n")
cat("- users with purchases:", sum(user_journeys$converted), "out of", nrow(user_journeys), "\n")
cat("- total revenue across sources:", 
    round(sum(campaigns_clean$revenue), 2), "(campaigns),",
    round(sum(web_clean$revenue), 2), "(web),",
    round(sum(journey_clean$order_value, na.rm = TRUE), 2), "(journey)\n")

# save cleaned datasets
write.csv(campaigns_clean, "campaigns_cleaned.csv", row.names = FALSE)
write.csv(social_clean, "social_cleaned.csv", row.names = FALSE)
write.csv(web_clean, "web_cleaned.csv", row.names = FALSE)
write.csv(journey_clean, "journey_cleaned.csv", row.names = FALSE)
write.csv(integrated_data, "integrated_data.csv", row.names = FALSE)
write.csv(user_journeys, "user_journeys.csv", row.names = FALSE)

cat("\ncleaned datasets saved\n")