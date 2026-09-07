-- Месячные продажи пяти выбранных SKU
-- Период исследования: 2023 год. Запускать отдельно.
SELECT
    product_id,
    DATE_TRUNC('month', purchase_datetime)::date AS month,
    SUM(quantity) AS units_sold,
    ROUND(SUM(total_price)::numeric, 0) AS revenue
FROM sales
WHERE product_id IN (45201, 16635, 37382, 5702, 26800)
  AND quantity > 0
  AND purchase_datetime >= '2023-01-01'
  AND purchase_datetime < '2024-01-01'
GROUP BY product_id, DATE_TRUNC('month', purchase_datetime)
ORDER BY product_id, month;
