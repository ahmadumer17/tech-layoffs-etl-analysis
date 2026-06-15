-- =============================================================================
-- parameterized_queries.sql
-- Tech Layoffs ETL Analysis | Ahmad Umer
-- =============================================================================
-- Structured views and parameterized queries enabling on-demand slicing
-- of the layoffs dataset by sector, region, and timeline.
--
-- These views are created on top of the layoffs table in layoffs_clean.db.
-- Run in SQLite:  sqlite3 layoffs_clean.db < parameterized_queries.sql
-- Or execute in Python:  conn.executescript(open('parameterized_queries.sql').read())
-- =============================================================================


-- =============================================================================
-- SECTION 1: BASE VIEWS (structured, reusable semantic layer)
-- =============================================================================

-- View 1: Clean fact layer with derived columns
-- Adds year, month, and quarter for time-based slicing.
DROP VIEW IF EXISTS v_layoffs_clean;
CREATE VIEW v_layoffs_clean AS
SELECT
    company,
    industry,
    country,
    stage,
    date,
    CAST(strftime('%Y', date) AS INTEGER)           AS year,
    CAST(strftime('%m', date) AS INTEGER)           AS month,
    strftime('%Y-%m', date)                          AS year_month,
    CASE
        WHEN CAST(strftime('%m', date) AS INTEGER) BETWEEN 1  AND 3  THEN 'Q1'
        WHEN CAST(strftime('%m', date) AS INTEGER) BETWEEN 4  AND 6  THEN 'Q2'
        WHEN CAST(strftime('%m', date) AS INTEGER) BETWEEN 7  AND 9  THEN 'Q3'
        WHEN CAST(strftime('%m', date) AS INTEGER) BETWEEN 10 AND 12 THEN 'Q4'
    END                                              AS quarter,
    total_laid_off,
    percentage_laid_off,
    funds_raised_millions
FROM layoffs
WHERE total_laid_off IS NOT NULL
  AND date IS NOT NULL;


-- View 2: Company-level rollup
-- One row per company with aggregate stats across all events.
DROP VIEW IF EXISTS v_company_summary;
CREATE VIEW v_company_summary AS
SELECT
    company,
    country,
    industry,
    COUNT(*)                          AS layoff_events,
    SUM(total_laid_off)               AS total_laid_off,
    ROUND(AVG(total_laid_off), 0)     AS avg_per_event,
    MIN(date)                         AS first_layoff_date,
    MAX(date)                         AS last_layoff_date,
    ROUND(AVG(percentage_laid_off), 4) AS avg_pct_laid_off
FROM v_layoffs_clean
GROUP BY company, country, industry;


-- View 3: Industry-level rollup
DROP VIEW IF EXISTS v_industry_summary;
CREATE VIEW v_industry_summary AS
SELECT
    industry,
    COUNT(*)                           AS layoff_events,
    COUNT(DISTINCT company)            AS companies_affected,
    SUM(total_laid_off)                AS total_laid_off,
    ROUND(AVG(total_laid_off), 0)      AS avg_per_event,
    ROUND(AVG(percentage_laid_off), 4) AS avg_pct_laid_off,
    MIN(date)                          AS first_layoff_date,
    MAX(date)                          AS last_layoff_date
FROM v_layoffs_clean
GROUP BY industry;


-- View 4: Country-level rollup
DROP VIEW IF EXISTS v_country_summary;
CREATE VIEW v_country_summary AS
SELECT
    country,
    COUNT(*)                  AS layoff_events,
    COUNT(DISTINCT company)   AS companies_affected,
    SUM(total_laid_off)       AS total_laid_off,
    ROUND(
        100.0 * SUM(total_laid_off) /
        (SELECT SUM(total_laid_off) FROM v_layoffs_clean),
        2
    )                         AS pct_of_global
FROM v_layoffs_clean
GROUP BY country;


-- View 5: Monthly trend with rolling 3-month average (SQLite window function)
DROP VIEW IF EXISTS v_monthly_trend;
CREATE VIEW v_monthly_trend AS
SELECT
    year_month,
    year,
    month,
    SUM(total_laid_off)   AS monthly_total,
    ROUND(
        AVG(SUM(total_laid_off)) OVER (
            ORDER BY year_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        0
    )                     AS rolling_3m_avg
FROM v_layoffs_clean
GROUP BY year_month, year, month;


-- =============================================================================
-- SECTION 2: PARAMETERIZED QUERIES
-- These use WHERE clause parameters (:param style for SQLite/Python binding).
-- Replace :param values directly in SQL, or pass via Python as shown below.
--
-- Python usage example:
--   conn.execute(query, {"industry": "Hardware", "year_start": 2022, "year_end": 2023})
-- =============================================================================


-- Parameterized Query 1: Slice by SECTOR (industry)
-- Param: :industry   e.g. 'Hardware', 'AI', 'Finance', 'Retail'
-- Param: :top_n      e.g. 10
-- -------------------------------------------------------
-- Python: conn.execute(Q1_SECTOR, {"industry": "Hardware", "top_n": 10})
SELECT
    company,
    country,
    SUM(total_laid_off)           AS total_laid_off,
    COUNT(*)                      AS layoff_events,
    ROUND(AVG(total_laid_off), 0) AS avg_per_event,
    MIN(date)                     AS first_event,
    MAX(date)                     AS last_event
FROM v_layoffs_clean
WHERE industry = :industry
GROUP BY company, country
ORDER BY total_laid_off DESC
LIMIT :top_n;


-- Parameterized Query 2: Slice by REGION (country)
-- Param: :country    e.g. 'United States', 'India', 'Germany'
-- Param: :year_start e.g. 2022
-- Param: :year_end   e.g. 2023
-- -------------------------------------------------------
SELECT
    industry,
    year,
    SUM(total_laid_off)           AS total_laid_off,
    COUNT(*)                      AS layoff_events,
    ROUND(AVG(total_laid_off), 0) AS avg_per_event
FROM v_layoffs_clean
WHERE country    = :country
  AND year BETWEEN :year_start AND :year_end
GROUP BY industry, year
ORDER BY year, total_laid_off DESC;


-- Parameterized Query 3: Slice by TIMELINE (year range)
-- Param: :year_start e.g. 2022
-- Param: :year_end   e.g. 2023
-- -------------------------------------------------------
SELECT
    year,
    quarter,
    industry,
    SUM(total_laid_off)           AS total_laid_off,
    COUNT(DISTINCT company)       AS companies_affected,
    COUNT(*)                      AS layoff_events
FROM v_layoffs_clean
WHERE year BETWEEN :year_start AND :year_end
GROUP BY year, quarter, industry
ORDER BY year, quarter, total_laid_off DESC;


-- Parameterized Query 4: Sector × Region × Timeline (combined slicer)
-- Param: :industry   (pass '%' to match all industries)
-- Param: :country    (pass '%' to match all countries)
-- Param: :year_start
-- Param: :year_end
-- -------------------------------------------------------
-- This is the self-serve query powering the Power BI export pipeline.
-- Passing wildcards lets analysts run it without hardcoding any dimension.
SELECT
    company,
    industry,
    country,
    year,
    quarter,
    SUM(total_laid_off)           AS total_laid_off,
    COUNT(*)                      AS layoff_events,
    ROUND(AVG(total_laid_off), 0) AS avg_per_event
FROM v_layoffs_clean
WHERE industry LIKE :industry
  AND country  LIKE :country
  AND year BETWEEN :year_start AND :year_end
GROUP BY company, industry, country, year, quarter
ORDER BY total_laid_off DESC;


-- Parameterized Query 5: Rolling trend for a specific country + industry
-- Param: :country
-- Param: :industry
-- -------------------------------------------------------
SELECT
    year_month,
    SUM(total_laid_off) AS monthly_total,
    ROUND(
        AVG(SUM(total_laid_off)) OVER (
            ORDER BY year_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        0
    ) AS rolling_3m_avg
FROM v_layoffs_clean
WHERE country  LIKE :country
  AND industry LIKE :industry
GROUP BY year_month
ORDER BY year_month;


-- =============================================================================
-- SECTION 3: POWER BI EXPORT QUERIES
-- These are the exact queries the export_for_powerbi.py script replicates
-- in Pandas — documented here so the SQL lineage is transparent.
-- =============================================================================

-- PBI Export 1: Company rankings (top 30)
SELECT
    company, country, industry,
    SUM(total_laid_off)           AS total_laid_off,
    COUNT(*)                      AS layoff_events,
    ROUND(AVG(total_laid_off), 0) AS avg_per_event,
    MIN(date)                     AS first_layoff,
    MAX(date)                     AS last_layoff,
    ROW_NUMBER() OVER (ORDER BY SUM(total_laid_off) DESC) AS rank
FROM v_layoffs_clean
GROUP BY company, country, industry
ORDER BY total_laid_off DESC
LIMIT 30;

-- PBI Export 2: Country summary (all countries)
SELECT
    country,
    SUM(total_laid_off)                           AS total_laid_off,
    COUNT(*)                                      AS layoff_events,
    COUNT(DISTINCT company)                       AS companies,
    ROUND(
        100.0 * SUM(total_laid_off) /
        SUM(SUM(total_laid_off)) OVER (),
        2
    )                                             AS pct_of_global,
    ROW_NUMBER() OVER (ORDER BY SUM(total_laid_off) DESC) AS rank
FROM v_layoffs_clean
GROUP BY country
ORDER BY total_laid_off DESC;

-- PBI Export 3: Industry summary
SELECT
    industry,
    SUM(total_laid_off)                            AS total_laid_off,
    COUNT(*)                                       AS layoff_events,
    COUNT(DISTINCT company)                        AS companies,
    ROUND(AVG(total_laid_off), 0)                  AS avg_per_event,
    ROUND(AVG(percentage_laid_off), 4)             AS avg_pct_laid_off,
    ROW_NUMBER() OVER (ORDER BY SUM(total_laid_off) DESC) AS rank
FROM v_layoffs_clean
GROUP BY industry
ORDER BY total_laid_off DESC;

-- PBI Export 4: Yearly trend with YoY change
SELECT
    year,
    SUM(total_laid_off)                           AS total_laid_off,
    COUNT(*)                                      AS layoff_events,
    COUNT(DISTINCT company)                       AS companies,
    SUM(total_laid_off) - LAG(SUM(total_laid_off)) OVER (ORDER BY year) AS yoy_change,
    ROUND(
        100.0 * (
            SUM(total_laid_off) - LAG(SUM(total_laid_off)) OVER (ORDER BY year)
        ) / LAG(SUM(total_laid_off)) OVER (ORDER BY year),
        2
    )                                             AS yoy_pct_change
FROM v_layoffs_clean
GROUP BY year
ORDER BY year;

-- PBI Export 5: Monthly rolling trend
SELECT
    year_month,
    year,
    SUM(total_laid_off)  AS total_laid_off,
    ROUND(
        AVG(SUM(total_laid_off)) OVER (
            ORDER BY year_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        0
    )                    AS rolling_3m
FROM v_layoffs_clean
GROUP BY year_month, year
ORDER BY year_month;
