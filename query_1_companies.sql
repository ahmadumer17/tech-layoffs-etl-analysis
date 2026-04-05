-- ============================================
-- Query 1: Top 20 Companies by Total Layoffs
-- Author: [Your Name]
-- Dataset: Global Tech Layoffs 2020-2026
-- ============================================

SELECT
    company,
    country,
    SUM(total_laid_off)     AS total_layoffs,
    COUNT(*)                AS total_events,
    MAX(date)               AS most_recent_event
FROM layoffs
WHERE total_laid_off IS NOT NULL
GROUP BY company, country
ORDER BY total_layoffs DESC
LIMIT 20;
