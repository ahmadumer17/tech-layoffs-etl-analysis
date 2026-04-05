-- ============================================
-- QUERY 4: YEARLY LAYOFF TREND
-- Author: [Your Name]
-- Dataset: Global Tech Layoffs 2020-2026
-- ============================================

query_4 = """
SELECT
    strftime('%Y', date)          AS year,
    SUM(total_laid_off)           AS total_layoffs,
    COUNT(*)                      AS total_events
FROM layoffs
WHERE total_laid_off IS NOT NULL
AND date IS NOT NULL
GROUP BY strftime('%Y', date)
ORDER BY year ASC;
"""
