-- ABC по выручке: товары
-- Период исследования: 2023 год. Запускать отдельно.
--ABC - скоры
WITH product_metrics AS (
	SELECT
		product_id,
		sum(total_price) AS revenue,
		sum(quantity) AS units_sold
	FROM sales s
	WHERE quantity > 0
      AND purchase_datetime >= '2023-01-01'
      AND purchase_datetime < '2024-01-01'
	GROUP BY 1
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
)
SELECT
    *,
    CASE
        WHEN cumulative_share_pct <= 80 THEN 'A'
        WHEN cumulative_share_pct <= 95 THEN 'B'
        ELSE 'C'
    END AS abc_class
FROM abc_metrics
ORDER BY revenue desc, product_id;
