-- ============================================
-- QUERY 2: TOTAL LAYOFFS BY COUNTRY
-- Author: [Ahmad Umer]
-- Dataset: Global Tech Layoffs 2020-2026
-- ============================================

query_2 = """
SELECT
    country,
    SUM(total_laid_off)           AS total_layoffs,
    COUNT(*)                      AS total_events,
    ROUND(AVG(total_laid_off), 0) AS avg_layoffs_per_event
FROM layoffs
WHERE total_laid_off IS NOT NULL
AND country != 'Unknown'
GROUP BY country
ORDER BY total_layoffs DESC
LIMIT 20;
"""
