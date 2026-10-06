-- Retention по когортам с нулями в наблюдаемых месяцах.
-- Период исследования: 2023 год. Запускать отдельно.
-- Полнота наблюдения задана концом периода, а не последней покупкой когорты.
WITH base_sales AS (
    SELECT client_id, purchase_datetime
    FROM sales
    WHERE quantity > 0
      AND purchase_datetime >= DATE '2023-01-01'
      AND purchase_datetime < DATE '2024-01-01'
),
customer_first_purchase AS (
    SELECT client_id,
           DATE_TRUNC('month', MIN(purchase_datetime))::date AS cohort_month
    FROM base_sales
    GROUP BY client_id
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM customer_first_purchase
    GROUP BY cohort_month
),
monthly_activity AS (
    SELECT f.cohort_month,
           DATE_TRUNC('month', s.purchase_datetime)::date AS activity_month,
           COUNT(DISTINCT s.client_id) AS active_clients
    FROM base_sales s
    JOIN customer_first_purchase f ON s.client_id = f.client_id
    GROUP BY f.cohort_month, DATE_TRUNC('month', s.purchase_datetime)
),
cohort_grid AS (
    SELECT c.cohort_month, c.cohort_size,
           m.activity_month::date AS activity_month,
           ((EXTRACT(YEAR FROM m.activity_month) - EXTRACT(YEAR FROM c.cohort_month)) * 12
            + EXTRACT(MONTH FROM m.activity_month) - EXTRACT(MONTH FROM c.cohort_month))::int AS month_number
    FROM cohort_sizes c
    CROSS JOIN LATERAL generate_series(
        c.cohort_month, DATE '2023-12-01', INTERVAL '1 month'
    ) AS m(activity_month)
),
filled_activity AS (
    SELECT g.cohort_month, g.month_number, g.cohort_size,
           COALESCE(a.active_clients, 0) AS active_clients
    FROM cohort_grid g
    LEFT JOIN monthly_activity a
      ON a.cohort_month = g.cohort_month
     AND a.activity_month = g.activity_month
)
SELECT cohort_month, month_number, active_clients, cohort_size,
       ROUND(100.0 * active_clients / NULLIF(cohort_size, 0), 2) AS retention_pct
FROM filled_activity
ORDER BY cohort_month, month_number;
