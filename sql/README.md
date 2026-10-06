# Каталог SQL-запросов

Каждый файл содержит один самостоятельный запрос. Выполняйте нужный файл в DBeaver или Metabase на базе с таблицей `sales`. Все запросы исследования используют положительное количество и период 2023 года. Не запускайте весь каталог одновременно на VPS.

## Ассортимент

[Исследование и бизнес-выводы](../docs/analysis/assortment.md) · [Сохранённые агрегаты](../data/summary/README.md)

- [ABC по выручке: товары](assortment/01_abc_product_scores.sql)
- [ABC по выручке: сводка](assortment/02_abc_summary.sql)
- [Двойной ABC: товары](assortment/03_dual_abc_scores.sql)
- [Двойной ABC: девять групп](assortment/04_dual_abc_summary.sql)
- [Цены и двойной ABC](assortment/05_abc_price_comparison.sql)
- [XYZ: товары, пороги 55/75%](assortment/06_xyz_product_scores.sql)
- [Исследовательский вариант XYZ: пороги 10/25%](assortment/07_xyz_classic_exploration.sql)
- [Распределение CV](assortment/08_cv_distribution.sql)
- [Итоговый XYZ: пороги 55/75%](assortment/09_xyz_adapted_summary.sql)
- [Комбинированные ABC-XYZ сегменты](assortment/10_abc_xyz_segments.sql)
- [Скидки по сегментам](assortment/11_segment_discounts.sql)
- [Группы скидок и продажи](assortment/12_discount_bands.sql)
- [Корреляция скидок и продаж по сегментам](assortment/13_discount_correlation.sql)
- [Товары CCZ для рассмотрения](assortment/14_ccz_review.sql)
- [CCZ: кандидаты по зафиксированным границам](assortment/15_ccz_priority_candidates.sql)
- [Месячные продажи пяти выбранных SKU](assortment/16_candidate_monthly_sales.sql)
Новые группы `assortment_action` и `discount_action` сохранены как агрегаты, без финальных CASE-правил. Девять сочетаний двойного ABC и девять групп действий — разные классификации. Запросы CCZ воспроизводят прежний отбор, а не новый список из 184 SKU.

## Клиентская база

[Исследование и программа CRM](../docs/analysis/customers.md) · [Сохранённые агрегаты](../data/summary/README.md)

- [Метрики клиентов](customers/01_customer_metrics.sql)
- [Сводка активности и ценности](customers/02_customer_summary.sql)
- [Перцентили RFM](customers/03_rfm_percentiles.sql)
- [Распределение покупательских дней](customers/04_frequency_distribution.sql)
- [RFM-оценки](customers/05_rfm_scores.sql)
- [Бизнес-сегменты RFM](customers/06_rfm_segments.sql)
- [Retention по когортам, включая нулевые наблюдаемые месяцы](customers/07_cohort_retention.sql)
- [Взвешенная retention-кривая по всем подходящим когортам](customers/08_retention_curve.sql)
- [Исследовательский LTV: переменный состав когорт](customers/09_ltv_exploration.sql)
- [LTV M0–M6: фиксированные когорты](customers/10_ltv_fixed_cohorts.sql)
- [Retention и выручка фиксированных когорт января–июня, M0–M6](customers/11_retention_revenue.sql)
- [Сценарный эффект роста M1-retention](customers/12_retention_scenarios.sql)
- [Повторная активность за 30/60/90 дней](customers/13_repeat_rate.sql)
- [Время до второго покупательского дня](customers/14_time_to_second_day.sql)

Методологические ограничения и различия исследовательских/итоговых вариантов описаны в [документации](../docs/methodology.md).

Запросы 07/08/11 учитывают нулевые наблюдаемые месяцы; будущие месяцы не считаются нулевым retention. Общая кривая 08 меняет состав допустимых когорт по горизонту, а 11 сохраняет фиксированный состав января–июня. [Локальные проверки SQL](../tests/README.md) используют синтетические данные и не заменяют пересчёт опубликованных агрегатов.
