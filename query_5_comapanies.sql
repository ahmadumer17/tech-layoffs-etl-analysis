-- ============================================
-- QUERY 5: ROLLING 3-MONTH LAYOFF TREND
-- Author: [Your Name]
-- Dataset: Global Tech Layoffs 2020-2026
-- ============================================

query_5 = """
WITH monthly_totals AS (
    SELECT
        strftime('%Y-%m', date)       AS month,
        SUM(total_laid_off)           AS monthly_layoffs
    FROM layoffs
    WHERE total_laid_off IS NOT NULL
    AND date IS NOT NULL
    GROUP BY strftime('%Y-%m', date)
)

SELECT
    month,
    monthly_layoffs,
    SUM(monthly_layoffs) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3_month_total
FROM monthly_totals
ORDER BY month ASC;
"""
