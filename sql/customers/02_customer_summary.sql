-- Сводка активности и ценности
-- Период исследования: 2023 год. Запускать отдельно.
--распределение клиентов по активности и ценности
WITH customer_metrics AS (
    SELECT
        client_id,
        COUNT(DISTINCT purchase_datetime) AS active_days,
        SUM(quantity) AS units_bought,
        SUM(total_price) AS revenue
    FROM sales
    WHERE quantity > 0
      AND purchase_datetime >= '2023-01-01'
      AND purchase_datetime < '2024-01-01'
    GROUP BY client_id
)
SELECT
    COUNT(*) AS customers_count,
    ROUND(AVG(active_days)::numeric, 2) AS avg_active_days,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY active_days)::numeric, 2) AS median_active_days,
    ROUND(AVG(revenue)::numeric, 0) AS avg_revenue,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY revenue)::numeric, 0) AS median_revenue
FROM customer_metrics;
