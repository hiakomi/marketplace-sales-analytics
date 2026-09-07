-- XYZ: товары, пороги 55/75%
-- Период исследования: 2023 год. Запускать отдельно.
--XYZ - анализ для проверки стабильности спроса на товары
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
    product_id,
    ROUND(avg_monthly_sales::numeric, 2) AS avg_monthly_sales,
    ROUND(stddev_monthly_sales::numeric, 2) AS stddev_monthly_sales,
    ROUND(variation_coef_pct::numeric, 2) AS variation_coef_pct,
    CASE
    	WHEN variation_coef_pct <= 55 THEN 'X'
    	WHEN variation_coef_pct <= 75 THEN 'Y'
    	ELSE 'Z'
END AS xyz_class
FROM xyz_metrics
ORDER BY variation_coef_pct;
