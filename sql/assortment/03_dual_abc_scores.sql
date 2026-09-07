-- Двойной ABC: товары
-- Период исследования: 2023 год. Запускать отдельно.
--ABC - анализ по двум метрикам и комбинирование скоров       
    WITH product_metrics AS (
    SELECT
        product_id,
        SUM(total_price) AS revenue,
        SUM(quantity) AS units_sold
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
        cumulative_revenue_pct,
        cumulative_units_pct,
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
)
SELECT
    product_id,
    revenue,
    units_sold,
    revenue_class,
    units_class,
    revenue_class || units_class AS abc_class
FROM abc_result
ORDER BY revenue DESC;
