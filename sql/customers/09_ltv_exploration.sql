-- Исследовательский LTV: переменный состав когорт
-- Период исследования: 2023 год. Запускать отдельно.
--Накопленная выручка на клиента
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
customer_monthly_revenue AS (
    SELECT
        s.client_id,
        f.cohort_month,
        DATE_TRUNC('month', s.purchase_datetime)::date AS activity_month,
        SUM(s.total_price) AS revenue
    FROM sales s
    JOIN customer_first_purchase f
        ON s.client_id = f.client_id
    WHERE s.quantity > 0
      AND s.purchase_datetime >= '2023-01-01'
      AND s.purchase_datetime < '2024-01-01'
    GROUP BY
        s.client_id,
        f.cohort_month,
        DATE_TRUNC('month', s.purchase_datetime)
),
cohort_revenue AS (
    SELECT
        cohort_month,
        (
            (EXTRACT(YEAR FROM activity_month) - EXTRACT(YEAR FROM cohort_month)) * 12
            + (EXTRACT(MONTH FROM activity_month) - EXTRACT(MONTH FROM cohort_month))
        )::int AS month_number,
        SUM(revenue) AS revenue
    FROM customer_monthly_revenue
    GROUP BY cohort_month, activity_month
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size
    FROM customer_first_purchase
    GROUP BY cohort_month
),
cohort_ltv AS (
    SELECT
        r.cohort_month,
        r.month_number,
        c.cohort_size,
        SUM(r.revenue) OVER (
            PARTITION BY r.cohort_month
            ORDER BY r.month_number
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue
    FROM cohort_revenue r
    JOIN cohort_sizes c
        ON r.cohort_month = c.cohort_month
)
SELECT
    month_number,
    SUM(cumulative_revenue) AS cumulative_revenue,
    SUM(cohort_size) AS customers_at_start,
    ROUND(
        (
            SUM(cumulative_revenue)
            / SUM(cohort_size)
        )::numeric,
        0
    ) AS cumulative_revenue_per_customer
FROM cohort_ltv
GROUP BY month_number
ORDER BY month_number;
