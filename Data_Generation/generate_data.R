# generating marketing data for assignment
# need jsonlite and XML packages

library(jsonlite)
library(XML)

setwd(getwd())
set.seed(123)

cat("making data files...\n")

# csv file - campaign performance
campaign_ids <- paste0("CMP", sprintf("%03d", 1:10))

campaign_data <- data.frame(
  campaign_id = campaign_ids,
  campaign_name = c("Summer Sale Email Blast", "Google Search - Running Shoes", 
                    "Facebook Brand Awareness", "Instagram Influencer Collab",
                    "Display Network Retargeting", "October Newsletter Email",
                    "YouTube Pre-roll Ads", "LinkedIn B2B Campaign",
                    "Twitter Flash Sale", "Google Shopping Feed"),
  channel = c("Email", "Google Ads", "Facebook", "Instagram", "Display",
              "Email", "YouTube", "LinkedIn", "Twitter", "Google Ads"),
  start_date = seq(as.Date("2024-10-01"), as.Date("2024-10-25"), length.out = 10),
  end_date = seq(as.Date("2024-10-08"), as.Date("2024-11-01"), length.out = 10),
  budget = c(500, 3500, 2000, 1500, 1200, 400, 2800, 1800, 800, 3200),
  stringsAsFactors = FALSE
)

# impressions vary by channel
campaign_data$impressions <- c(50000, 125000, 180000, 95000, 220000, 
                               45000, 150000, 35000, 88000, 110000)

# clicks based on typical CTR for each channel
campaign_data$clicks <- round(c(50000*0.05, 125000*0.04, 180000*0.025, 
                                95000*0.032, 220000*0.005, 45000*0.048,
                                150000*0.018, 35000*0.035, 88000*0.028, 110000*0.042))

# conversions from clicks
campaign_data$conversions <- round(c(campaign_data$clicks[1]*0.05, campaign_data$clicks[2]*0.04,
                                     campaign_data$clicks[3]*0.02, campaign_data$clicks[4]*0.038,
                                     campaign_data$clicks[5]*0.015, campaign_data$clicks[6]*0.045,
                                     campaign_data$clicks[7]*0.025, campaign_data$clicks[8]*0.032,
                                     campaign_data$clicks[9]*0.028, campaign_data$clicks[10]*0.048))

# revenue calc
avg_order_values <- c(89.99, 124.50, 95.00, 108.75, 78.50, 92.00, 115.25, 145.00, 82.99, 118.50)
campaign_data$revenue <- campaign_data$conversions * avg_order_values

# some metrics
campaign_data$ctr <- round((campaign_data$clicks / campaign_data$impressions) * 100, 2)
campaign_data$conversion_rate <- round((campaign_data$conversions / campaign_data$clicks) * 100, 2)
campaign_data$cpc <- round(campaign_data$budget / campaign_data$clicks, 2)
campaign_data$roas <- round(campaign_data$revenue / campaign_data$budget, 2)

write.csv(campaign_data, "Digital_Campaigns.csv", row.names = FALSE)
cat("csv done\n")

# json file - social media posts
social_posts <- list()

social_posts[[1]] <- list(
  post_id = "POST001", platform = "Facebook", campaign_id = "CMP003",
  post_date = "2024-10-08T10:30:00Z",
  post_text = "New collection just dropped! Check out our latest styles 👟✨",
  likes = 5420, comments = 234, shares = 156, clicks = 4500,
  reach = 180000, engagement_rate = 3.21
)

social_posts[[2]] <- list(
  post_id = "POST002", platform = "Facebook", campaign_id = "CMP003",
  post_date = "2024-10-12T14:15:00Z",
  post_text = "Weekend sale alert! 25% off on selected items",
  likes = 3890, comments = 167, shares = 89, clicks = 3200,
  reach = 145000, engagement_rate = 2.86
)

social_posts[[3]] <- list(
  post_id = "POST003", platform = "Instagram", campaign_id = "CMP004",
  post_date = "2024-10-10T09:00:00Z",
  post_text = "Style inspo for your next run 🏃‍♀️ #RunningShoes #Fitness",
  likes = 8920, comments = 445, shares = 0, clicks = 3040,
  reach = 95000, engagement_rate = 9.86, saves = 567
)

social_posts[[4]] <- list(
  post_id = "POST004", platform = "Instagram", campaign_id = "CMP004",
  post_date = "2024-10-14T16:45:00Z",
  post_text = "Behind the scenes with our athletes 💪",
  likes = 7234, comments = 312, shares = 0, clicks = 2450,
  reach = 88000, engagement_rate = 8.57, saves = 423
)

social_posts[[5]] <- list(
  post_id = "POST005", platform = "Twitter", campaign_id = "CMP009",
  post_date = "2024-10-22T11:20:00Z",
  post_text = "FLASH SALE! Next 2 hours only. Use code FLASH25 🔥",
  likes = 2156, comments = 89, shares = 234, clicks = 2464,
  reach = 88000, engagement_rate = 2.82
)

social_posts[[6]] <- list(
  post_id = "POST006", platform = "Twitter", campaign_id = "CMP009",
  post_date = "2024-10-23T13:30:00Z",
  post_text = "Last chance! Flash sale ends tonight 🎯",
  likes = 1678, comments = 67, shares = 178, clicks = 1980,
  reach = 72000, engagement_rate = 2.67
)

social_posts[[7]] <- list(
  post_id = "POST007", platform = "LinkedIn", campaign_id = "CMP008",
  post_date = "2024-10-20T08:00:00Z",
  post_text = "How we're revolutionizing workplace wellness programs",
  likes = 456, comments = 78, shares = 123, clicks = 1225,
  reach = 35000, engagement_rate = 1.88
)

json_data <- toJSON(social_posts, pretty = TRUE, auto_unbox = TRUE)
write(json_data, "Social_Engagement.json")
cat("json done\n")

# xml file - web analytics
root <- newXMLNode("web_analytics")
addAttributes(root, export_date = "2024-11-01", period = "October 2024")

sources <- c("Facebook", "Google Ads", "Instagram", "Email", "Display", 
             "YouTube", "LinkedIn", "Twitter", "Direct", "Organic")

for(i in 1:50) {
  session <- newXMLNode("session", parent = root)
  
  source_weights <- c(0.18, 0.15, 0.12, 0.08, 0.05, 0.08, 0.04, 0.06, 0.14, 0.10)
  traffic_source <- sample(sources, 1, prob = source_weights)
  
  addChildren(session,
              newXMLNode("session_id", paste0("SESS", sprintf("%04d", i))),
              newXMLNode("date", format(sample(seq(as.Date("2024-10-01"), 
                                                   as.Date("2024-10-31"), by = "day"), 1), "%Y-%m-%d")),
              newXMLNode("source", traffic_source),
              newXMLNode("medium", ifelse(traffic_source %in% c("Direct", "Organic"), traffic_source, "cpc")),
              newXMLNode("campaign", ifelse(traffic_source == "Facebook", "CMP003",
                                            ifelse(traffic_source == "Instagram", "CMP004",
                                                   ifelse(traffic_source == "Email", sample(c("CMP001", "CMP006"), 1),
                                                          ifelse(traffic_source == "Google Ads", sample(c("CMP002", "CMP010"), 1), "none"))))),
              newXMLNode("pageviews", sample(1:15, 1, prob = c(0.3, 0.25, 0.18, 0.12, 0.08, 0.04, 0.02, 0.01, rep(0.001, 7)))),
              newXMLNode("duration_seconds", round(rnorm(1, 180, 90))),
              newXMLNode("bounce", sample(c("true", "false"), 1, prob = c(0.45, 0.55))),
              newXMLNode("transactions", sample(0:1, 1, prob = c(0.96, 0.04))),
              newXMLNode("revenue", ifelse(runif(1) < 0.04, round(runif(1, 50, 200), 2), 0)),
              newXMLNode("device", sample(c("mobile", "desktop", "tablet"), 1, prob = c(0.55, 0.38, 0.07)))
  )
}

saveXML(root, "Web_Analytics.xml")
cat("xml done\n")

# txt file - customer journey logs
log_entries <- c()

for(user_num in 1:15) {
  user_id <- paste0("USER_", sprintf("%05d", 10000 + user_num))
  num_touchpoints <- sample(3:8, 1)
  start_date <- sample(seq(as.Date("2024-10-01"), as.Date("2024-10-25"), by = "day"), 1)
  
  campaigns_available <- c("CMP001", "CMP002", "CMP003", "CMP004", "CMP005", 
                           "CMP006", "CMP007", "CMP008", "CMP009", "CMP010")
  first_campaign <- sample(campaigns_available, 1)
  
  timestamp <- format(start_date + runif(1, 0, 24)*3600, "%Y-%m-%d %H:%M:%S")
  log_entries <- c(log_entries, 
                   sprintf("%s | %s | AD_IMPRESSION | %s | channel=%s", 
                           timestamp, user_id, first_campaign,
                           campaign_data$channel[which(campaign_data$campaign_id == first_campaign)]))
  
  for(touch in 2:num_touchpoints) {
    days_later <- sample(0:7, 1)
    touch_date <- start_date + days_later
    timestamp <- format(touch_date + runif(1, 0, 24)*3600, "%Y-%m-%d %H:%M:%S")
    
    if(touch == 2) {
      event <- sample(c("AD_CLICK", "AD_IMPRESSION"), 1, prob = c(0.7, 0.3))
      if(event == "AD_CLICK") {
        log_entries <- c(log_entries,
                         sprintf("%s | %s | %s | %s | destination=website", 
                                 timestamp, user_id, event, first_campaign))
      } else {
        another_campaign <- sample(campaigns_available[campaigns_available != first_campaign], 1)
        log_entries <- c(log_entries,
                         sprintf("%s | %s | %s | %s | channel=%s", 
                                 timestamp, user_id, event, another_campaign,
                                 campaign_data$channel[which(campaign_data$campaign_id == another_campaign)]))
      }
    } else if(touch == 3) {
      event <- sample(c("SITE_VISIT", "AD_CLICK", "EMAIL_OPEN"), 1, prob = c(0.5, 0.3, 0.2))
      if(event == "SITE_VISIT") {
        log_entries <- c(log_entries,
                         sprintf("%s | %s | %s | %s | pages_viewed=%d", 
                                 timestamp, user_id, event, "none", sample(2:8, 1)))
      } else if(event == "AD_CLICK") {
        log_entries <- c(log_entries,
                         sprintf("%s | %s | %s | %s | destination=website", 
                                 timestamp, user_id, event, first_campaign))
      } else {
        email_campaign <- sample(c("CMP001", "CMP006"), 1)
        log_entries <- c(log_entries,
                         sprintf("%s | %s | %s | %s | subject=newsletter", 
                                 timestamp, user_id, event, email_campaign))
      }
    } else if(touch >= 4 && touch < num_touchpoints) {
      event <- sample(c("SITE_VISIT", "PRODUCT_VIEW", "ADD_TO_CART", "EMAIL_CLICK"), 1)
      if(event == "SITE_VISIT") {
        log_entries <- c(log_entries,
                         sprintf("%s | %s | %s | %s | pages_viewed=%d", 
                                 timestamp, user_id, event, "none", sample(3:10, 1)))
      } else if(event == "PRODUCT_VIEW") {
        log_entries <- c(log_entries,
                         sprintf("%s | %s | %s | %s | product_id=PROD%03d", 
                                 timestamp, user_id, event, "none", sample(1:50, 1)))
      } else if(event == "ADD_TO_CART") {
        log_entries <- c(log_entries,
                         sprintf("%s | %s | %s | %s | product_id=PROD%03d,quantity=%d", 
                                 timestamp, user_id, event, "none", sample(1:50, 1), sample(1:3, 1)))
      } else {
        email_campaign <- sample(c("CMP001", "CMP006"), 1)
        log_entries <- c(log_entries,
                         sprintf("%s | %s | %s | %s | destination=website", 
                                 timestamp, user_id, event, email_campaign))
      }
    } else {
      converted <- runif(1) < 0.35
      if(converted) {
        order_value <- round(runif(1, 60, 180), 2)
        log_entries <- c(log_entries,
                         sprintf("%s | %s | PURCHASE | %s | order_value=%.2f,items=%d", 
                                 timestamp, user_id, first_campaign, order_value, sample(1:4, 1)))
      } else {
        log_entries <- c(log_entries,
                         sprintf("%s | %s | CART_ABANDON | none | cart_value=%.2f", 
                                 timestamp, user_id, round(runif(1, 40, 150), 2)))
      }
    }
  }
  log_entries <- c(log_entries, "")
}

writeLines(log_entries, "Customer_Journey.txt")
cat("txt done\n")

cat("\nall files created in:", getwd(), "\n")
cat("total budget:", sum(campaign_data$budget), "\n")
cat("total revenue:", round(sum(campaign_data$revenue), 2), "\n")