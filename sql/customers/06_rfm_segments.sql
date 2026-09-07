-- Бизнес-сегменты RFM
-- Период исследования: 2023 год. Запускать отдельно.
--Распределение по бизнес - сегментам
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
),
rfm_segments AS (
    SELECT
        *,
        CONCAT(r_score, f_score, m_score) AS rfm_score,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'Лучшие клиенты'
            WHEN r_score >= 3 AND f_score >= 4 AND m_score >= 3
                THEN 'Лояльные'
            WHEN r_score >= 4 AND f_score IN (2, 3) AND m_score >= 2
                THEN 'Перспективные'
            WHEN r_score = 5 AND f_score = 1
                THEN 'Новые'
            WHEN r_score >= 4 AND f_score <= 2
                THEN 'Активные низкой частоты'
            WHEN r_score = 3
                THEN 'Требуют внимания'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 3
                THEN 'Под риском'
            WHEN r_score <= 2 AND m_score >= 4
                THEN 'Ценные, требуют реактивации'
            WHEN r_score <= 2 AND m_score = 3
                THEN 'Уходящие'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2
                THEN 'Спящие'
            ELSE 'Остальные'
        END AS segment
    FROM rfm_scores
)
SELECT
    segment,
    COUNT(*) AS customers_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customers_share_pct,
    ROUND(SUM(monetary)::numeric, 0) AS revenue,
    ROUND(
        (
            100.0 * SUM(monetary)
            / SUM(SUM(monetary)) OVER ()
        )::numeric,
        2
    ) AS revenue_share_pct,
    ROUND(AVG(recency_days)::numeric, 1) AS avg_recency_days,
    ROUND(AVG(frequency)::numeric, 2) AS avg_frequency,
    ROUND(AVG(monetary)::numeric, 0) AS avg_monetary
FROM rfm_segments
GROUP BY segment
ORDER BY revenue DESC;
