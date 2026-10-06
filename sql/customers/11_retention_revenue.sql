-- Retention и выручка на клиента: фиксированные когорты января-июня, M0-M6.
-- Период исследования: 2023 год. Запускать отдельно.
-- Знаменатель сохраняет неактивные когорты. Нет активных клиентов -> ARPA = NULL.
WITH base_sales AS (
    SELECT client_id, purchase_datetime, total_price
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
eligible_customers AS (
    SELECT client_id, cohort_month
    FROM customer_first_purchase
    WHERE cohort_month <= DATE '2023-06-01'
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM eligible_customers
    GROUP BY cohort_month
),
monthly_activity AS (
    SELECT e.cohort_month,
           ((EXTRACT(YEAR FROM s.purchase_datetime) - EXTRACT(YEAR FROM e.cohort_month)) * 12
            + EXTRACT(MONTH FROM s.purchase_datetime) - EXTRACT(MONTH FROM e.cohort_month))::int AS month_number,
           COUNT(DISTINCT s.client_id) AS active_clients,
           SUM(s.total_price) AS revenue
    FROM base_sales s
    JOIN eligible_customers e ON s.client_id = e.client_id
    GROUP BY e.cohort_month, month_number
),
cohort_grid AS (
    SELECT c.cohort_month, c.cohort_size, m.month_number
    FROM cohort_sizes c
    CROSS JOIN generate_series(0, 6) AS m(month_number)
),
filled_activity AS (
    SELECT g.month_number, g.cohort_size,
           COALESCE(a.active_clients, 0) AS active_clients,
           COALESCE(a.revenue, 0) AS revenue
    FROM cohort_grid g
    LEFT JOIN monthly_activity a
      ON a.cohort_month = g.cohort_month
     AND a.month_number = g.month_number
),
summary AS (
    SELECT month_number,
           SUM(active_clients) AS active_clients,
           SUM(cohort_size) AS cohort_size,
           SUM(revenue) AS revenue
    FROM filled_activity
    GROUP BY month_number
)
SELECT month_number, active_clients, cohort_size,
       ROUND(100.0 * active_clients / NULLIF(cohort_size, 0), 2) AS retention_pct,
       ROUND((revenue / NULLIF(cohort_size, 0))::numeric, 0) AS revenue_per_original_customer,
       ROUND((revenue / NULLIF(active_clients, 0))::numeric, 0) AS revenue_per_active_customer
FROM summary
ORDER BY month_number;
