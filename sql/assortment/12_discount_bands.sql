-- Группы скидок и продажи
-- Период исследования: 2023 год. Запускать отдельно.
--проверка паттерна "чем больше скидка - тем выше продажи"
WITH product_metrics AS (
    SELECT
        product_id,
        SUM(quantity) AS units_sold,
        100.0 * SUM(discount_per_item * quantity) / NULLIF(SUM(price_per_item * quantity), 0) AS discount_rate_pct
    FROM sales
    WHERE quantity > 0
      AND purchase_datetime >= '2023-01-01'
      AND purchase_datetime < '2024-01-01'
    GROUP BY product_id
),
discount_groups AS (
    SELECT
        product_id,
        units_sold,
        FLOOR(discount_rate_pct / 5) * 5 AS discount_from
    FROM product_metrics
)
SELECT
    CONCAT(
        discount_from::int,
        '–',
        (discount_from + 5)::int,
        '%'
    ) AS discount_group,
    COUNT(*) AS products_count,
    ROUND(AVG(units_sold)::numeric, 1) AS avg_units_sold
FROM discount_groups
GROUP BY discount_from
ORDER BY discount_from;
