-- Корреляция скидок и продаж по сегментам
-- Период исследования: 2023 год. Запускать отдельно.
--Связь размера скидки с объёмом продаж отдельно внутри каждого ABC–XYZ сегмента
WITH product_metrics AS (
    SELECT
        product_id,
        SUM(total_price) AS revenue,
        SUM(quantity) AS units_sold,
        SUM(price_per_item * quantity) AS gross_revenue,
        SUM(discount_per_item * quantity) AS discount_amount,
        100.0 * SUM(discount_per_item * quantity) / NULLIF(SUM(price_per_item * quantity), 0) AS discount_rate_pct
    FROM sales
    WHERE quantity > 0
      AND purchase_datetime >= '2023-01-01'
      AND purchase_datetime < '2024-01-01'
    GROUP BY product_id
),
abc_metrics AS (
    SELECT
        product_id,
        revenue,
        units_sold,
        discount_rate_pct,
        SUM(revenue) OVER (
            ORDER BY revenue DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / SUM(revenue) OVER () * 100 AS cumulative_revenue_pct,
        SUM(units_sold) OVER (
            ORDER BY units_sold DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )::numeric / SUM(units_sold) OVER () * 100 AS cumulative_units_pct
    FROM product_metrics
),
abc_result AS (
    SELECT
        product_id,
        revenue,
        units_sold,
        discount_rate_pct,
        CASE
            WHEN cumulative_revenue_pct <= 80 THEN 'A'
            WHEN cumulative_revenue_pct <= 95 THEN 'B'
            ELSE 'C'
        END AS revenue_class,
        CASE
            WHEN cumulative_units_pct <= 80 THEN 'A'
            WHEN cumulative_units_pct <= 95 THEN 'B'
            ELSE 'C'
        END AS units_class
    FROM abc_metrics
),
months AS (
    SELECT generate_series(
        '2023-01-01'::date,
        '2023-12-01'::date,
        interval '1 month'
    )::date AS month
),
product_months AS (
    SELECT
        p.product_id,
        m.month
    FROM product_metrics p
    CROSS JOIN months m
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
        STDDEV_POP(units_sold) / NULLIF(AVG(units_sold), 0) * 100 AS variation_coef_pct
    FROM filled_sales
    GROUP BY product_id
),
xyz_result AS (
    SELECT
        product_id,
        CASE
            WHEN variation_coef_pct <= 55 THEN 'X'
            WHEN variation_coef_pct <= 75 THEN 'Y'
            ELSE 'Z'
        END AS xyz_class
    FROM xyz_metrics
),
final_segments AS (
    SELECT
        a.product_id,
        a.revenue,
        a.units_sold,
        a.discount_rate_pct,
        a.revenue_class || a.units_class || x.xyz_class AS segment
    FROM abc_result a
    JOIN xyz_result x
        ON a.product_id = x.product_id
)
SELECT
    segment,
    COUNT(*) AS products_count,
    ROUND(AVG(discount_rate_pct)::numeric, 2) AS avg_discount_pct,
    ROUND(CORR(discount_rate_pct, units_sold)::numeric, 4) AS discount_sales_correlation
FROM final_segments
GROUP BY segment
ORDER BY segment;
