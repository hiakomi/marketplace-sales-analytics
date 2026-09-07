-- Распределение покупательских дней
-- Период исследования: 2023 год. Запускать отдельно.
--Смотрим распределение frequency
WITH customer_metrics AS (
    SELECT
        client_id,
        COUNT(DISTINCT purchase_datetime) AS frequency
    FROM sales
    WHERE quantity > 0
      AND purchase_datetime >= '2023-01-01'
      AND purchase_datetime < '2024-01-01'
    GROUP BY client_id
)
SELECT
    frequency,
    COUNT(*) AS customers_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customers_share_pct
FROM customer_metrics
GROUP BY frequency
ORDER BY frequency;
