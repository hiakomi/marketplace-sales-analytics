-- LTV M0–M6: фиксированные когорты
-- Период исследования: 2023 год. Запускать отдельно.
--6-месячный LTV на одинаковом наборе когорт
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
months AS (
    SELECT generate_series(0, 6) AS month_number
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size
    FROM eligible_customers
    GROUP BY cohort_month
),
monthly_revenue AS (
    SELECT
        e.cohort_month,
        (
            (EXTRACT(YEAR FROM s.purchase_datetime) - EXTRACT(YEAR FROM e.cohort_month)) * 12
            + (EXTRACT(MONTH FROM s.purchase_datetime) - EXTRACT(MONTH FROM e.cohort_month))
        )::int AS month_number,
        SUM(s.total_price) AS revenue
    FROM sales s
    JOIN eligible_customers e
        ON s.client_id = e.client_id
    WHERE s.quantity > 0
      AND s.purchase_datetime >= '2023-01-01'
      AND s.purchase_datetime < '2024-01-01'
    GROUP BY
        e.cohort_month,
        month_number
),
cohort_grid AS (
    SELECT
        c.cohort_month,
        c.cohort_size,
        m.month_number
    FROM cohort_sizes c
    CROSS JOIN months m
),
filled_revenue AS (
    SELECT
        g.cohort_month,
        g.cohort_size,
        g.month_number,
        COALESCE(r.revenue, 0) AS revenue
    FROM cohort_grid g
    LEFT JOIN monthly_revenue r
        ON g.cohort_month = r.cohort_month
       AND g.month_number = r.month_number
),
cohort_ltv AS (
    SELECT
        cohort_month,
        cohort_size,
        month_number,
        SUM(revenue) OVER (
            PARTITION BY cohort_month
            ORDER BY month_number
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue
    FROM filled_revenue
),
ltv_curve AS (
    SELECT
        month_number,
        SUM(cumulative_revenue) AS cumulative_revenue,
        SUM(cohort_size) AS customers_count,
        SUM(cumulative_revenue) / SUM(cohort_size) AS cumulative_revenue_per_customer
    FROM cohort_ltv
    GROUP BY month_number
)
SELECT
    month_number,
    ROUND(cumulative_revenue::numeric, 0) AS cumulative_revenue,
    customers_count,
    ROUND(cumulative_revenue_per_customer::numeric, 0) AS cumulative_revenue_per_customer,
    ROUND(
        (
            100.0 * cumulative_revenue_per_customer
            / FIRST_VALUE(cumulative_revenue_per_customer) OVER (ORDER BY month_number)
            - 100
        )::numeric,
        2
    ) AS growth_vs_m0_pct
FROM ltv_curve
ORDER BY month_number;
