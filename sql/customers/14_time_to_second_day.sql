-- Время до второго покупательского дня
-- Период исследования: 2023 год. Запускать отдельно.
--через какое время совершается повторная покупка
WITH purchase_days AS (
    SELECT DISTINCT
        client_id,
        purchase_datetime AS purchase_date
    FROM sales
    WHERE quantity > 0
      AND purchase_datetime >= '2023-01-01'
      AND purchase_datetime < '2024-01-01'
),
ranked_purchases AS (
    SELECT
        client_id,
        purchase_date,
        ROW_NUMBER() OVER (
            PARTITION BY client_id
            ORDER BY purchase_date
        ) AS purchase_number
    FROM purchase_days
),
first_second_purchase AS (
    SELECT
        client_id,
        MIN(purchase_date) FILTER (WHERE purchase_number = 1) AS first_purchase_date,
        MIN(purchase_date) FILTER (WHERE purchase_number = 2) AS second_purchase_date
    FROM ranked_purchases
    GROUP BY client_id
),
repeat_customers AS (
    SELECT
        client_id,
        second_purchase_date - first_purchase_date AS days_to_second_purchase
    FROM first_second_purchase
    WHERE second_purchase_date IS NOT NULL
)
SELECT
    COUNT(*) AS repeat_customers,
    ROUND(AVG(days_to_second_purchase)::numeric, 1) AS avg_days,
    PERCENTILE_CONT(0.25) WITHIN GROUP (
        ORDER BY days_to_second_purchase
    ) AS p25_days,
    PERCENTILE_CONT(0.50) WITHIN GROUP (
        ORDER BY days_to_second_purchase
    ) AS median_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (
        ORDER BY days_to_second_purchase
    ) AS p75_days,
    PERCENTILE_CONT(0.90) WITHIN GROUP (
        ORDER BY days_to_second_purchase
    ) AS p90_days
FROM repeat_customers;
