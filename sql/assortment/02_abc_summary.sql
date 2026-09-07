-- ABC по выручке: сводка
-- Период исследования: 2023 год. Запускать отдельно.
--ABC - сводка по классам
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
        revenue / SUM(revenue) OVER () * 100 AS revenue_share_pct,
        SUM(revenue) OVER (
            ORDER BY revenue DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / SUM(revenue) OVER () * 100 AS cumulative_share_pct
    FROM product_metrics
),
abc_result AS (
    SELECT
        *,
        CASE
            WHEN cumulative_share_pct <= 80 THEN 'A'
            WHEN cumulative_share_pct <= 95 THEN 'B'
            ELSE 'C'
        END AS abc_class
    FROM abc_metrics
)
SELECT
    abc_class,
    COUNT(*) AS products_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS products_share_pct,
    ROUND(SUM(revenue)::numeric, 0) AS revenue,
    ROUND((100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER ())::numeric, 2) AS revenue_share_pct
FROM abc_result
GROUP BY abc_class
ORDER BY
    CASE abc_class
        WHEN 'A' THEN 1
        WHEN 'B' THEN 2
        WHEN 'C' THEN 3
    END;
