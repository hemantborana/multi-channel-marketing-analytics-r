# exploring the data files

library(jsonlite)
library(XML)
library(dplyr)

setwd("C:/Users/User/projects/S5/dmv-m8/Generated_data")

cat("loading data files...\n\n")



# 1. CSV - Digital Campaigns
campaigns <- read.csv("Digital_Campaigns.csv", stringsAsFactors = FALSE)

cat("--- Digital Campaigns (CSV) ---\n")
cat("rows:", nrow(campaigns), "\n")
cat("columns:", ncol(campaigns), "\n")
str(campaigns)
cat("\nfirst few rows:\n")
head(campaigns, 3)
cat("\nsummary stats:\n")
summary(campaigns[, c("budget", "impressions", "clicks", "conversions", "revenue")])

# check for missing values
cat("\nmissing values:", sum(is.na(campaigns)), "\n")

# channel distribution
cat("\ncampaigns by channel:\n")
table(campaigns$channel)

cat("\n\n")



# 2. JSON - Social Engagement
social_raw <- fromJSON("Social_Engagement.json", simplifyDataFrame = TRUE)

cat("--- Social Engagement (JSON) ---\n")
cat("number of posts:", nrow(social_raw), "\n")

cat("columns:", paste(names(social_raw), collapse = ", "), "\n")
cat("\nfirst post:\n")
print(social_raw[1, ])

# platform distribution
cat("\nposts by platform:\n")
table(social_raw$platform)

# engagement metrics
cat("\nengagement summary:\n")
summary(social_raw[, c("likes", "comments", "shares", "clicks")])

cat("\n\n")



# 3. XML - Web Analytics
xml_doc <- xmlParse("Web_Analytics.xml")
root <- xmlRoot(xml_doc)

cat("--- Web Analytics (XML) ---\n")
cat("number of sessions:", xmlSize(root), "\n")

# extract data from xml
sessions_list <- xmlApply(root, function(x) {
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

web_df <- do.call(rbind, sessions_list)

cat("\ncolumns:", paste(names(web_df), collapse = ", "), "\n")
cat("\nfirst few sessions:\n")
head(web_df, 3)

# traffic sources
cat("\ntraffic by source:\n")
table(web_df$source)

cat("\ndevice breakdown:\n")
table(web_df$device)

# conversion rate
cat("\ntotal transactions:", sum(web_df$transactions), "\n")
cat("conversion rate:", round(mean(web_df$transactions) * 100, 2), "%\n")

cat("\n\n")



# 4. TXT - Customer Journey
journey_raw <- readLines("Customer_Journey.txt")

cat("--- Customer Journey (TXT) ---\n")
cat("total lines:", length(journey_raw), "\n")

# filter out empty lines
journey_lines <- journey_raw[journey_raw != ""]
cat("log entries:", length(journey_lines), "\n")

# show sample entries
cat("\nsample log entries:\n")
head(journey_lines, 5)

# parse the log structure
# format: timestamp | user_id | event_type | campaign_id | details
parse_log <- function(line) {
  parts <- strsplit(line, " \\| ")[[1]]
  if(length(parts) >= 4) {
    return(data.frame(
      timestamp = parts[1],
      user_id = parts[2],
      event_type = parts[3],
      campaign_id = parts[4],
      details = ifelse(length(parts) > 4, parts[5], ""),
      stringsAsFactors = FALSE
    ))
  }
  return(NULL)
}

journey_df <- do.call(rbind, lapply(journey_lines, parse_log))

cat("\nparsed journey data:\n")
cat("rows:", nrow(journey_df), "\n")

# event types
cat("\nevents breakdown:\n")
table(journey_df$event_type)

# unique users
cat("\nunique users:", length(unique(journey_df$user_id)), "\n")

# users who purchased
purchases <- journey_df[journey_df$event_type == "PURCHASE", ]
cat("users who converted:", nrow(purchases), "\n")

cat("\n\n")

# checking data relationships
cat("--- Data Relationships Check ---\n")

# campaigns in social data
social_campaigns <- unique(social_raw$campaign_id)
cat("campaigns with social posts:", paste(social_campaigns, collapse = ", "), "\n")

# campaigns in web data
web_campaigns <- unique(web_df$campaign[web_df$campaign != "none"])
cat("campaigns driving web traffic:", paste(web_campaigns, collapse = ", "), "\n")

# campaigns in journey data
journey_campaigns <- unique(journey_df$campaign_id[journey_df$campaign_id != "none"])
cat("campaigns in customer journey:", paste(sort(journey_campaigns), collapse = ", "), "\n")

# check if all match with main campaign list
all_campaign_ids <- campaigns$campaign_id
cat("\nall campaigns in CSV:", paste(all_campaign_ids, collapse = ", "), "\n")

cat("\ndata quality notes:\n")
cat("- date formats need standardization\n")
cat("- some campaigns appear across multiple sources\n")
cat("- web data has 'none' for organic traffic\n")
cat("- journey logs need parsing for detailed analysis\n")
