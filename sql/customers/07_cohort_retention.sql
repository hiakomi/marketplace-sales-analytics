-- Retention по когортам
-- Период исследования: 2023 год. Запускать отдельно.
--Когортный анализ
WITH customer_first_purchase AS (
    SELECT
        client_id,
        DATE_TRUNC('month', MIN(purchase_datetime))::date AS cohort_month
    FROM sales
    WHERE quantity > 0
      AND purchase_datetime >= '2023-01-01'
      AND purchase_datetime < '2024-01-01'
    GROUP BY client_id
),
customer_activity AS (
    SELECT DISTINCT
        client_id,
        DATE_TRUNC('month', purchase_datetime)::date AS activity_month
    FROM sales
    WHERE quantity > 0
      AND purchase_datetime >= '2023-01-01'
      AND purchase_datetime < '2024-01-01'
),
cohort_activity AS (
    SELECT
        a.client_id,
        f.cohort_month,
        a.activity_month,
        (
            (EXTRACT(YEAR FROM a.activity_month) - EXTRACT(YEAR FROM f.cohort_month)) * 12
            + (EXTRACT(MONTH FROM a.activity_month) - EXTRACT(MONTH FROM f.cohort_month))
        )::int AS month_number
    FROM customer_activity a
    JOIN customer_first_purchase f
        ON a.client_id = f.client_id
    WHERE a.activity_month >= f.cohort_month
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size
    FROM customer_first_purchase
    GROUP BY cohort_month
),
retention AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT client_id) AS active_clients
    FROM cohort_activity
    GROUP BY cohort_month, month_number
)
SELECT
    r.cohort_month,
    r.month_number,
    r.active_clients,
    c.cohort_size,
    ROUND(
        100.0 * r.active_clients / c.cohort_size,
        2
    ) AS retention_pct
FROM retention r
JOIN cohort_sizes c
    ON r.cohort_month = c.cohort_month
ORDER BY r.cohort_month, r.month_number;
