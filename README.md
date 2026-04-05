# End-to-End ETL Pipeline & Exploratory Data Analysis: Global Tech Layoffs

![Python](https://img.shields.io/badge/Python-3.10-blue)
![SQL](https://img.shields.io/badge/SQL-SQLite-lightgrey)
![Plotly](https://img.shields.io/badge/Visualization-Plotly-orange)
![Status](https://img.shields.io/badge/Status-Complete-green)

## Project Overview

An end-to-end data pipeline analyzing 3,612 tech layoff events across 
6 years (March 2020 — March 2026), covering over 840,000 job losses 
across 50+ countries. Built to simulate a real-world corporate analytics 
workflow using Python for transformation, SQLite for storage, and 
Plotly for interactive visualization.

## Business Questions Answered

- Which companies conducted the most layoffs between 2020 and 2026?
- Which countries and industries were hit hardest?
- What does the temporal trend reveal about the tech sector contraction?
- How does a 3-month rolling average smooth layoff volatility over time?

## Tech Stack

| Tool | Purpose |
|------|---------|
| Python (Pandas) | Data cleaning and transformation |
| SQLAlchemy | Database connection and ORM layer |
| SQLite | Local relational database storage |
| SQL | Analytical querying and aggregation |
| Plotly | Interactive data visualization |
| Google Colab | Development environment |

## Pipeline Architecture
```
Raw CSV → Pandas EDA → Data Cleaning → SQLite Database → SQL Queries → Plotly Dashboard
```

## Key Findings

- **United States** dominated with 584,000 layoffs across 1,737 events
- **2023 was the peak year** with 264,320 layoffs — driven by simultaneous 
  mass cuts at Meta, Amazon, and Google following aggressive over-hiring in 2021
- **Amazon** led all companies with 58,024 layoffs across 12 separate events
- **Hardware** had the highest average cut size at 1,792 per event
- **AI** was the only industry with minimal layoffs — 1,532 total — 
  reflecting active expansion rather than contraction
- The **rolling 3-month peak** occurred in January 2023 at 153,967 — 
  the single most severe period of tech sector contraction in the dataset

## Project Structure
```
tech-layoffs-etl-analysis/
├── data/
│   └── layoffs.csv
├── database/
│   └── layoffs_clean.db
├── notebooks/
│   └── layoffs_analysis.ipynb
├── queries/
│   ├── query_1_companies.sql
│   ├── query_2_countries.sql
│   ├── query_3_industries.sql
│   ├── query_4_yearly_trend.sql
│   └── query_5_rolling_trend.sql
├── requirements.txt
└── README.md
```

## How to Run

1. Clone the repository
2. Install dependencies: `pip install -r requirements.txt`
3. Open `notebooks/layoffs_analysis.ipynb` in Jupyter or Google Colab
4. Run all cells sequentially from top to bottom

## Dataset

Source: [Kaggle Tech Layoffs Dataset](https://www.kaggle.com/datasets/swaptr/layoffs-2022)  
Maintainer: Roger Lee  
Coverage: March 2020 — March 2026  
Raw rows: 4,319 | Clean rows: 3,612

## Author

[Ahmad Umer] | [www.linkedin.com/in/ahmad-umer-413531276] | [Ahmadumer1701@gmail.com]
