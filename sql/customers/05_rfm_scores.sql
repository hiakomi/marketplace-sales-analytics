-- RFM-оценки
-- Период исследования: 2023 год. Запускать отдельно.
--полноценный RFM 
WITH customer_metrics AS (
    SELECT
        client_id,
        MAX(gender) AS gender,
        MIN(purchase_datetime) AS first_purchase_date,
        MAX(purchase_datetime) AS last_purchase_date,
        '2024-01-01'::date - MAX(purchase_datetime) AS recency_days,
        COUNT(DISTINCT purchase_datetime) AS frequency,
        SUM(total_price) AS monetary
    FROM sales
    WHERE quantity > 0
      AND purchase_datetime >= '2023-01-01'
      AND purchase_datetime < '2024-01-01'
    GROUP BY client_id
),
rfm_scores AS (
    SELECT
        *,
        CASE
            WHEN recency_days <= 33 THEN 5
            WHEN recency_days <= 81 THEN 4
            WHEN recency_days <= 135 THEN 3
            WHEN recency_days <= 214 THEN 2
            ELSE 1
        END AS r_score,
        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            WHEN frequency = 4 THEN 4
            ELSE 5
        END AS f_score,
        CASE
            WHEN monetary <= 341150 THEN 1
            WHEN monetary <= 937152 THEN 2
            WHEN monetary <= 1812834 THEN 3
            WHEN monetary <= 3267837 THEN 4
            ELSE 5
        END AS m_score
    FROM customer_metrics
)
SELECT
    client_id,
    gender,
    first_purchase_date,
    last_purchase_date,
    recency_days,
    frequency,
    ROUND(monetary::numeric, 0) AS monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_score
FROM rfm_scores
ORDER BY r_score DESC, f_score DESC, m_score DESC;
