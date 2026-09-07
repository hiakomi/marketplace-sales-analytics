-- Повторная активность за 30/60/90 дней
-- Период исследования: 2023 год. Запускать отдельно.
--Когда происходит повторная покупка и сколько клиентов удается до нее довести
WITH customer_first_purchase AS (
    SELECT
        client_id,
        MIN(purchase_datetime) AS first_purchase_date
    FROM sales
    WHERE quantity > 0
      AND purchase_datetime >= '2023-01-01'
      AND purchase_datetime < '2024-01-01'
    GROUP BY client_id
),
customer_activity AS (
    SELECT DISTINCT
        client_id,
        purchase_datetime AS activity_date
    FROM sales
    WHERE quantity > 0
      AND purchase_datetime >= '2023-01-01'
      AND purchase_datetime < '2024-01-01'
),
horizons AS (
    SELECT 30 AS days
    UNION ALL
    SELECT 60
    UNION ALL
    SELECT 90
),
eligible_customers AS (
    SELECT
        f.client_id,
        f.first_purchase_date,
        h.days
    FROM customer_first_purchase f
    CROSS JOIN horizons h
    WHERE f.first_purchase_date + h.days * INTERVAL '1 day' < '2024-01-01'
),
repeat_flags AS (
    SELECT
        e.client_id,
        e.days,
        MAX(
            CASE
                WHEN a.activity_date > e.first_purchase_date
                 AND a.activity_date <= e.first_purchase_date + e.days * INTERVAL '1 day'
                THEN 1
                ELSE 0
            END
        ) AS repeated
    FROM eligible_customers e
    LEFT JOIN customer_activity a
        ON e.client_id = a.client_id
    GROUP BY e.client_id, e.days
)
SELECT
    days AS window_days,
    COUNT(*) AS eligible_customers,
    SUM(repeated) AS repeat_customers,
    ROUND(
        100.0 * SUM(repeated) / COUNT(*),
        2
    ) AS repeat_rate_pct
FROM repeat_flags
GROUP BY days
ORDER BY days;
