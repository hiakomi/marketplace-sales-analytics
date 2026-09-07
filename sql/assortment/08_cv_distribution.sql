-- Распределение CV
-- Период исследования: 2023 год. Запускать отдельно.
--Просмотр распределения стабильности спроса, чтобы установить границы скоров
WITH months AS (
    SELECT generate_series(
        '2023-01-01'::date,
        '2023-12-01'::date,
        interval '1 month'
    )::date AS month
),
products AS (
    SELECT DISTINCT product_id
    FROM sales
    WHERE quantity > 0
      AND purchase_datetime >= '2023-01-01'
      AND purchase_datetime < '2024-01-01'
),
monthly_sales AS (
    SELECT
        product_id,
        DATE_TRUNC('month', purchase_datetime)::date AS month,
        SUM(quantity) AS units_sold
    FROM sales
    WHERE quantity > 0
      AND purchase_datetime >= '2023-01-01'
      AND purchase_datetime < '2024-01-01'
    GROUP BY product_id, DATE_TRUNC('month', purchase_datetime)
),
product_months AS (
    SELECT
        p.product_id,
        m.month
    FROM products p
    CROSS JOIN months m
),
filled_sales AS (
    SELECT
        pm.product_id,
        pm.month,
        COALESCE(ms.units_sold, 0) AS units_sold
    FROM product_months pm
    LEFT JOIN monthly_sales ms
        ON pm.product_id = ms.product_id
       AND pm.month = ms.month
),
xyz_metrics AS (
    SELECT
        product_id,
        AVG(units_sold) AS avg_monthly_sales,
        STDDEV_POP(units_sold) AS stddev_monthly_sales,
        STDDEV_POP(units_sold) / NULLIF(AVG(units_sold), 0) * 100 AS variation_coef_pct
    FROM filled_sales
    GROUP BY product_id
)
SELECT
    ROUND(MIN(variation_coef_pct)::numeric, 2) AS min_cv,
    ROUND(PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY variation_coef_pct)::numeric, 2) AS p10,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY variation_coef_pct)::numeric, 2) AS p25,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY variation_coef_pct)::numeric, 2) AS median,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY variation_coef_pct)::numeric, 2) AS p75,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY variation_coef_pct)::numeric, 2) AS p90,
    ROUND(MAX(variation_coef_pct)::numeric, 2) AS max_cv
FROM xyz_metrics;
