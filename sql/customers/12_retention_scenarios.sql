-- Сценарный эффект роста M1-retention
-- Период исследования: 2023 год. Запускать отдельно.
--сценарный анализ M1-retention
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
eligible_customers AS (
    SELECT
        client_id,
        cohort_month
    FROM customer_first_purchase
    WHERE cohort_month <= '2023-06-01'
),
cohort_size AS (
    SELECT
        COUNT(*) AS customers_count
    FROM eligible_customers
),
m1_metrics AS (
    SELECT
        COUNT(DISTINCT s.client_id) AS active_clients,
        SUM(s.total_price) AS revenue
    FROM sales s
    JOIN eligible_customers e
        ON s.client_id = e.client_id
    WHERE s.quantity > 0
      AND DATE_TRUNC('month', s.purchase_datetime)::date
          = (e.cohort_month + INTERVAL '1 month')::date
),
baseline AS (
    SELECT
        c.customers_count,
        m.active_clients,
        m.revenue,
        100.0 * m.active_clients / c.customers_count AS retention_pct,
        m.revenue / m.active_clients AS revenue_per_active_customer
    FROM cohort_size c
    CROSS JOIN m1_metrics m
),
scenarios AS (
    SELECT 0 AS retention_uplift_pp
    UNION ALL
    SELECT 1
    UNION ALL
    SELECT 3
    UNION ALL
    SELECT 5
)
SELECT
    retention_uplift_pp,
    ROUND(retention_pct::numeric, 2) AS baseline_retention_pct,
    ROUND((retention_pct + retention_uplift_pp)::numeric, 2) AS scenario_retention_pct,
    ROUND(
        (customers_count * retention_uplift_pp / 100.0)::numeric,
        0
    ) AS extra_active_clients,
    ROUND(revenue_per_active_customer::numeric, 0) AS revenue_per_active_customer,
    ROUND(
        (
            customers_count
            * retention_uplift_pp / 100.0
            * revenue_per_active_customer
        )::numeric,
        0
    ) AS incremental_revenue
FROM baseline
CROSS JOIN scenarios
ORDER BY retention_uplift_pp;
