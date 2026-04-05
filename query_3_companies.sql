-- ============================================
-- QUERY 3: TOTAL LAYOFFS BY INDUSTRY
-- Author: [Ahmad Umer]
-- Dataset: Global Tech Layoffs 2020-2026
-- ============================================

query_3 = """
SELECT
    industry,
    SUM(total_laid_off)           AS total_layoffs,
    COUNT(*)                      AS total_events,
    ROUND(AVG(total_laid_off), 0) AS avg_layoffs_per_event
FROM layoffs
WHERE total_laid_off IS NOT NULL
AND industry != 'Unknown'
GROUP BY industry
ORDER BY total_layoffs DESC;
"""
