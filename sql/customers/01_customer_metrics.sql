-- Метрики клиентов
-- Период исследования: 2023 год. Запускать отдельно.
--клиентская витрина
WITH customer_metrics AS (
    SELECT
        client_id,
        MAX(gender) AS gender,
        MIN(purchase_datetime) AS first_purchase_date,
        MAX(purchase_datetime) AS last_purchase_date,
        COUNT(DISTINCT purchase_datetime) AS active_days,
        SUM(quantity) AS units_bought,
        SUM(total_price) AS revenue
    FROM sales
    WHERE quantity > 0
      AND purchase_datetime >= '2023-01-01'
      AND purchase_datetime < '2024-01-01'
    GROUP BY client_id
)
SELECT *
FROM customer_metrics
ORDER BY revenue DESC;
