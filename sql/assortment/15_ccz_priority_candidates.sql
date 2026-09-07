-- CCZ: кандидаты по зафиксированным границам
-- Период исследования: 2023 год. Запускать отдельно.
--Пять товаров выделены как приоритетные кандидаты на пересмотр ассортиментной целесообразности. 
--Они одновременно относятся к CCZ-сегменту, находятся в нижнем квартиле CCZ по выручке и объёму продаж 
--и в верхнем квартиле по нестабильности спроса.
WITH product_metrics AS (
    SELECT
        product_id,
        SUM(total_price) AS revenue,
        SUM(quantity) AS units_sold,
        SUM(price_per_item * quantity) AS gross_revenue,
        SUM(discount_per_item * quantity) AS discount_amount
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
        gross_revenue,
        discount_amount,
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
        *,
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
        AVG(units_sold) AS avg_monthly_sales,
        COUNT(*) FILTER (WHERE units_sold > 0) AS active_months,
        STDDEV_POP(units_sold) / NULLIF(AVG(units_sold), 0) * 100 AS variation_coef_pct
    FROM filled_sales
    GROUP BY product_id
),
xyz_result AS (
    SELECT
        *,
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
        a.gross_revenue,
        a.discount_amount,
        a.revenue_class || a.units_class || x.xyz_class AS segment,
        x.avg_monthly_sales,
        x.active_months,
        x.variation_coef_pct
    FROM abc_result a
    JOIN xyz_result x
        ON a.product_id = x.product_id
)
SELECT
    product_id,
    ROUND(revenue::numeric, 0) AS revenue,
    units_sold,
    active_months,
    ROUND(avg_monthly_sales::numeric, 1) AS avg_monthly_sales,
    ROUND(variation_coef_pct::numeric, 2) AS cv_pct,
    ROUND(
        (revenue / NULLIF(units_sold, 0))::numeric,
        2
    ) AS avg_price_per_unit,
    ROUND(
        (
            100.0 * discount_amount
            / NULLIF(gross_revenue, 0)
        )::numeric,
        2
    ) AS discount_rate_pct
FROM final_segments
WHERE segment = 'CCZ'
  AND revenue <= 3401900
  AND units_sold <= 810
  AND variation_coef_pct >= 95.12
ORDER BY revenue ASC;
