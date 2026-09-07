-- Перцентили RFM
-- Период исследования: 2023 год. Запускать отдельно.
--Смотрим распределения данных, чтобы определить границы скоров 
WITH customer_metrics AS (
    SELECT
        client_id,
        '2024-01-01'::date - MAX(purchase_datetime) AS recency_days,
        COUNT(DISTINCT purchase_datetime) AS frequency,
        SUM(total_price) AS monetary
    FROM sales
    WHERE quantity > 0
      AND purchase_datetime >= '2023-01-01'
      AND purchase_datetime < '2024-01-01'
    GROUP BY client_id
)
SELECT
    MIN(recency_days) AS r_min,
    PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY recency_days) AS r_p20,
    PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY recency_days) AS r_p40,
    PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY recency_days) AS r_p60,
    PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY recency_days) AS r_p80,
    MAX(recency_days) AS r_max,
    MIN(frequency) AS f_min,
    PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY frequency) AS f_p20,
    PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY frequency) AS f_p40,
    PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY frequency) AS f_p60,
    PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY frequency) AS f_p80,
    MAX(frequency) AS f_max,
    ROUND(MIN(monetary)::numeric, 0) AS m_min,
    ROUND(PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY monetary)::numeric, 0) AS m_p20,
    ROUND(PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY monetary)::numeric, 0) AS m_p40,
    ROUND(PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY monetary)::numeric, 0) AS m_p60,
    ROUND(PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY monetary)::numeric, 0) AS m_p80,
    ROUND(MAX(monetary)::numeric, 0) AS m_max
FROM customer_metrics;
