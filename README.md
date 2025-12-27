# Multi-Channel Marketing Analytics with R

A comprehensive data analytics project integrating multiple data sources (CSV, JSON, XML, TXT) to analyze digital marketing performance across channels using R, with advanced attribution modeling and automated reporting.

![R](https://img.shields.io/badge/R-276DC3?style=flat&logo=r&logoColor=white)
![ggplot2](https://img.shields.io/badge/ggplot2-visualization-blue)
![plotly](https://img.shields.io/badge/plotly-interactive-orange)
![Status](https://img.shields.io/badge/status-complete-success)

## 📊 Project Overview

This project demonstrates end-to-end multi-source data analytics for digital marketing, including:
- Integration of 4 heterogeneous data sources
- Robust ETL pipeline with data quality controls
- Multi-channel attribution modeling (4 methods)
- Customer journey mapping and funnel analysis
- 8 professional visualizations (static + interactive)
- Automated R Markdown reporting

**Business Context:** Analyzing a fictional e-commerce company's digital marketing campaigns across Email, Google Ads, Facebook, Instagram, Display, YouTube, LinkedIn, and Twitter.

## 🎯 Key Features

- **Multi-Source Data Integration**: CSV, JSON, XML, and text log processing
- **Attribution Models**: First-touch, Last-touch, Linear, and Time-decay
- **Advanced Analytics**: Correlation analysis, efficiency metrics, ROI optimization
- **Interactive Visualizations**: Plotly charts with hover details and drill-down
- **Automated Reporting**: Reproducible R Markdown reports with embedded visualizations
- **Professional Code Quality**: Clean, documented, human-readable R code

## 📈 Key Findings

- **Overall ROAS**: 6.38x return on ad spend
- **Best Channel**: Email campaigns (22.4x ROAS)
- **Conversion Rate**: 20% of tracked users
- **Cart Abandonment**: 46.67% with $116.69 recovery opportunity
- **Customer Journey**: Converters have 40% more touchpoints (6.67 vs 4.75)

## 🚀 Getting Started

### Prerequisites

```r
# Required R packages
install.packages(c(
  "dplyr",
  "tidyr",
  "ggplot2",
  "plotly",
  "jsonlite",
  "XML",
  "DT",
  "scales", 
  "lubridate",
  "htmlwidgets"
))
```

### Installation

```bash
# Clone the repository
git clone https://github.com/hemantborana/multi-channel-marketing-analytics.git

# Navigate to project directory
cd multi-channel-marketing-analytics
```

### Running the Analysis

**Option 1: Run Complete Pipeline**
```r
# Set working directory
setwd("path/to/multi-channel-marketing-analytics")

# Generate data
source("Data_Generation/generate_data.R")

# Explore data
source("data_exploration.R")

# Run ETL pipeline
source("etl_pipeline.R")

# Perform analytics
source("advanced_analytics.R")

# Create visualizations
source("visualizations.R")

# Generate report
rmarkdown::render("marketing_analytics_report.Rmd")
```

**Option 2: Use Existing Data**
If you want to skip data generation and use the provided datasets:
```r
# Start from ETL or analytics
source("etl_pipeline.R")
source("advanced_analytics.R")
```

**Option 3: View Report Only**
Simply open `marketing_analytics_report.html` in your browser.

## 📊 Visualizations

### Static Visualizations (ggplot2)
1. **Channel Performance Comparison** - Faceted metrics (ROAS, CTR, Conversion Rate)
2. **Attribution Model Comparison** - Stacked bar chart across 4 models
3. **Conversion Funnel** - Customer journey drop-off analysis
4. **Customer Journey Timelines** - Event sequences for converters
5. **Revenue vs Budget by Channel** - Dual-axis comparison

### Interactive Visualizations (plotly)
6. **ROAS vs Budget Scatter** - Bubble chart with hover details
7. **Campaign Efficiency Heatmap** - Normalized performance matrix
8. **Campaign Dashboard** - Multi-panel interactive view

## 🔍 Analytics Methodology

### Data Integration
- **CSV**: Structured campaign performance data
- **JSON**: Semi-structured social media metrics
- **XML**: Web analytics session data
- **TXT**: Unstructured customer journey logs

### ETL Pipeline
1. **Extract**: Load data using format-specific parsers
2. **Transform**: Clean, standardize, and derive new features
3. **Load**: Create integrated datasets with proper joins

### Attribution Models

**First-Touch Attribution**
```
Credit = 100% to first campaign interaction
```

**Last-Touch Attribution**
```
Credit = 100% to last campaign before conversion
```

**Linear Attribution**
```
Credit = Equally distributed across all touchpoints
```

**Time-Decay Attribution**
```
Credit = Exponentially weighted by recency
Weight = exp(-days_before_conversion / 7)
```

## 📋 Key Metrics

| Metric | Value |
|--------|-------|
| Total Budget | $17,700 |
| Total Revenue | $113,019 |
| Overall ROAS | 6.38x |
| Total Campaigns | 10 |
| Channels Analyzed | 8 |
| Conversion Rate | 20% |
| Avg Journey Length | 246 days |
| Avg Touchpoints | 5.13 |

## 💡 Business Recommendations

### 1. Budget Reallocation
- **Increase**: Email (22.4x ROAS), Google Shopping, Instagram
- **Reduce**: Display (1.05x ROAS), YouTube, LinkedIn

### 2. Cart Abandonment Recovery
- Automated email sequences
- Retargeting campaigns
- Limited-time discount codes

### 3. Multi-Touch Attribution
- Move beyond last-click attribution
- Recognize assist campaigns (CMP001, CMP008)
- Optimize for full journey value

### 4. Engagement Optimization
- Increase touchpoint frequency
- Multi-channel nurture campaigns
- Content marketing initiatives

## 🛠️ Technical Stack

- **Language**: R (v4.x)
- **Data Manipulation**: dplyr, tidyr
- **Visualization**: ggplot2, plotly
- **Data Import**: jsonlite, XML
- **Reporting**: R Markdown, knitr
- **Interactive Tables**: DT

## 📚 Documentation

- **[REFLECTION.md](REFLECTION.md)**: Detailed project reflection with challenges and learnings
- **[Report HTML](marketing_analytics_report.html)**: Comprehensive analysis report
- **Code Comments**: All scripts thoroughly documented

## 🎓 Learning Outcomes

- Multi-source data integration techniques
- ETL pipeline development best practices
- Marketing attribution modeling
- Customer journey analysis
- Advanced data visualization
- Automated reporting workflows

## 📝 Use Cases

This project demonstrates skills applicable to:
- **Marketing Analytics**: Campaign performance optimization
- **Data Engineering**: Multi-source ETL pipelines
- **Business Intelligence**: Executive reporting
- **Customer Analytics**: Journey mapping and segmentation
- **Data Visualization**: Interactive dashboards

## 🤝 Contributing

This is an academic project, but suggestions and feedback are welcome! Feel free to:
- Open issues for bugs or improvements
- Fork and experiment with the code
- Share your own marketing analytics insights

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Hemant Borana**
- Academic Project: Data Modeling and Visualization (Module 8)
- University: Amity University Online
- Date: December 2025

## 🙏 Acknowledgments

- Course instructors for project guidance
- R community for excellent packages (tidyverse, plotly)
- Fictional data based on realistic marketing scenarios

## 📧 Contact

For questions or feedback:
- Email: [Hemant Borana](hemantpb123@gmail.com)
- LinkedIn: [Hemant Borana](www.linkedin.com/in/hemant-parasmal-borana)
- GitHub: [@hemantborana](https://github.com/hemantborana)

---

⭐ **If you find this project useful, please star the repository!**

*Last Updated: December 27, 2025*