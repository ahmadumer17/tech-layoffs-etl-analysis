"""
export_for_powerbi.py
=====================
Pulls from layoffs.csv (downloads from GitHub if missing),
runs all transformations, and exports 6 Power BI-ready CSVs to
powerbi_integration/output/.

Output tables
-------------
pbi_fact_layoffs.csv          — clean fact table (1 row per layoff event)
pbi_company_rankings.csv      — top companies by total layoffs
pbi_country_summary.csv       — layoffs by country
pbi_industry_summary.csv      — layoffs by industry
pbi_yearly_trend.csv          — yearly aggregates
pbi_rolling_trend.csv         — 3-month rolling average by month

Usage
-----
    python export_for_powerbi.py
"""

import os
import urllib.request
import pandas as pd
import numpy as np

HERE   = os.path.dirname(os.path.abspath(__file__))
ROOT   = os.path.abspath(os.path.join(HERE, ".."))
OUT    = os.path.join(HERE, "output")
os.makedirs(OUT, exist_ok=True)

RAW_CSV = os.path.join(ROOT, "layoffs.csv")
GITHUB_URL = (
    "https://raw.githubusercontent.com/"
    "ahmadumer17/tech-layoffs-etl-analysis/main/layoffs.csv"
)

def ensure_csv():
    if not os.path.exists(RAW_CSV):
        print("  Downloading layoffs.csv from GitHub …")
        urllib.request.urlretrieve(GITHUB_URL, RAW_CSV)

def clean(df):
    df = df.copy()
    df.columns = df.columns.str.strip().str.lower().str.replace(" ", "_")
    # parse date
    df["date"] = pd.to_datetime(df["date"], errors="coerce")
    df = df.dropna(subset=["date"])
    # numeric columns
    for col in ["total_laid_off", "percentage_laid_off", "funds_raised_millions"]:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")
    # drop rows with no layoff count
    df = df.dropna(subset=["total_laid_off"])
    df["total_laid_off"] = df["total_laid_off"].astype(int)
    # derived columns
    df["year"]  = df["date"].dt.year
    df["month"] = df["date"].dt.to_period("M").astype(str)
    df["year_month"] = df["date"].dt.strftime("%Y-%m")
    df["industry"]  = df["industry"].fillna("Unknown")
    df["country"]   = df["country"].fillna("Unknown")
    df["stage"]     = df["stage"].fillna("Unknown")
    return df

def run():
    print("\n=== Tech Layoffs → Power BI Export ===\n")

    # 1. Load
    print("[1/7] Loading data …")
    ensure_csv()
    raw = pd.read_csv(RAW_CSV)
    print(f"  Raw rows: {len(raw):,}")
    df = clean(raw)
    print(f"  Clean rows: {len(df):,}")

    # 2. Fact table
    print("[2/7] Building fact table …")
    fact_cols = [
        "company", "industry", "country", "stage",
        "date", "year", "month", "year_month",
        "total_laid_off", "percentage_laid_off", "funds_raised_millions"
    ]
    fact_cols = [c for c in fact_cols if c in df.columns]
    pbi_fact = df[fact_cols].copy()

    # 3. Company rankings
    print("[3/7] Building company rankings …")
    company = (
        df.groupby("company")
        .agg(
            total_laid_off   = ("total_laid_off", "sum"),
            layoff_events    = ("total_laid_off", "count"),
            first_layoff     = ("date", "min"),
            last_layoff      = ("date", "max"),
            industry         = ("industry", lambda x: x.mode()[0]),
            country          = ("country", lambda x: x.mode()[0]),
        )
        .reset_index()
        .sort_values("total_laid_off", ascending=False)
    )
    company["rank"] = range(1, len(company) + 1)
    company["avg_per_event"] = (
        company["total_laid_off"] / company["layoff_events"]
    ).round(0).astype(int)
    top_companies = company.head(30)

    # 4. Country summary
    print("[4/7] Building country summary …")
    country_df = (
        df.groupby("country")
        .agg(
            total_laid_off = ("total_laid_off", "sum"),
            layoff_events  = ("total_laid_off", "count"),
            companies      = ("company", "nunique"),
        )
        .reset_index()
        .sort_values("total_laid_off", ascending=False)
    )
    total_global = country_df["total_laid_off"].sum()
    country_df["pct_of_global"] = (
        country_df["total_laid_off"] / total_global * 100
    ).round(2)
    country_df["rank"] = range(1, len(country_df) + 1)

    # 5. Industry summary
    print("[5/7] Building industry summary …")
    industry_df = (
        df.groupby("industry")
        .agg(
            total_laid_off   = ("total_laid_off", "sum"),
            layoff_events    = ("total_laid_off", "count"),
            companies        = ("company", "nunique"),
            avg_pct_laid_off = ("percentage_laid_off", "mean"),
        )
        .reset_index()
        .sort_values("total_laid_off", ascending=False)
    )
    industry_df["avg_per_event"] = (
        industry_df["total_laid_off"] / industry_df["layoff_events"]
    ).round(0).astype(int)
    industry_df["avg_pct_laid_off"] = industry_df["avg_pct_laid_off"].round(4)
    industry_df["rank"] = range(1, len(industry_df) + 1)

    # 6. Yearly trend
    print("[6/7] Building yearly trend …")
    yearly = (
        df.groupby("year")
        .agg(
            total_laid_off = ("total_laid_off", "sum"),
            layoff_events  = ("total_laid_off", "count"),
            companies      = ("company", "nunique"),
            countries      = ("country", "nunique"),
        )
        .reset_index()
        .sort_values("year")
    )
    yearly["yoy_change"] = yearly["total_laid_off"].diff()
    yearly["yoy_pct_change"] = (
        yearly["total_laid_off"].pct_change() * 100
    ).round(2)

    # 7. Rolling 3-month trend
    print("[7/7] Building rolling 3-month trend …")
    monthly = (
        df.groupby("year_month")
        .agg(total_laid_off=("total_laid_off", "sum"))
        .reset_index()
        .sort_values("year_month")
    )
    monthly["rolling_3m"] = (
        monthly["total_laid_off"].rolling(window=3, min_periods=1).mean()
    ).round(0).astype(int)
    monthly["rolling_3m_peak"] = monthly["rolling_3m"] == monthly["rolling_3m"].max()
    monthly["date"] = pd.to_datetime(monthly["year_month"])
    monthly["year"] = monthly["date"].dt.year

    # Export
    print("\nWriting CSVs to", OUT)
    exports = {
        "pbi_fact_layoffs.csv"       : pbi_fact,
        "pbi_company_rankings.csv"   : top_companies,
        "pbi_country_summary.csv"    : country_df,
        "pbi_industry_summary.csv"   : industry_df,
        "pbi_yearly_trend.csv"       : yearly,
        "pbi_rolling_trend.csv"      : monthly,
    }
    for fname, frame in exports.items():
        path = os.path.join(OUT, fname)
        frame.to_csv(path, index=False)
        print(f"  ✓ {fname}  ({len(frame):,} rows)")

    print("\n=== Export complete ===")
    print(f"Load all 6 CSVs from  {OUT}  into Power BI Desktop.")
    print("Then apply DAX measures from  powerbi_integration/dax_measures.txt\n")

if __name__ == "__main__":
    run()
