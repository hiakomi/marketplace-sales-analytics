-- Retention и выручка на клиента
-- Период исследования: 2023 год. Запускать отдельно.
--проверка гипотезы о том, что 
--одним из главных рычагов LTV выглядит увеличение повторных покупок
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
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size
    FROM eligible_customers
    GROUP BY cohort_month
),
monthly_activity AS (
    SELECT
        e.cohort_month,
        ((EXTRACT(YEAR FROM s.purchase_datetime) - EXTRACT(YEAR FROM e.cohort_month)) * 12
        + (EXTRACT(MONTH FROM s.purchase_datetime) - EXTRACT(MONTH FROM e.cohort_month)))::int AS month_number,
        COUNT(DISTINCT s.client_id) AS active_clients,
        SUM(s.total_price) AS revenue
    FROM sales s
    JOIN eligible_customers e
        ON s.client_id = e.client_id
    WHERE s.quantity > 0
      AND s.purchase_datetime >= '2023-01-01'
      AND s.purchase_datetime < '2024-01-01'
    GROUP BY e.cohort_month, month_number
),
summary AS (
    SELECT
        a.month_number,
        SUM(a.active_clients) AS active_clients,
        SUM(c.cohort_size) AS cohort_size,
        SUM(a.revenue) AS revenue
    FROM monthly_activity a
    JOIN cohort_sizes c
        ON a.cohort_month = c.cohort_month
    WHERE a.month_number BETWEEN 0 AND 6
    GROUP BY a.month_number
)
SELECT
    month_number,
    active_clients,
    cohort_size,
    ROUND(100.0 * active_clients / cohort_size, 2) AS retention_pct,
    ROUND((revenue / cohort_size)::numeric, 0) AS revenue_per_original_customer,
    ROUND((revenue / active_clients)::numeric, 0) AS revenue_per_active_customer
FROM summary
ORDER BY month_number;
