-- Synthetic data only. All totals can be checked by hand.
-- Jan: 2 customers, M0 revenue 340; one returns in M2 (60) and M6 (40).
-- Feb: 1 customer, M0 revenue 80; never returns.
-- Jun: 1 customer, M0 revenue 120; returns in M1 (30).
-- Jul/Dec: later cohorts, excluded from fixed Jan-Jun metrics.
-- Duplicate customer/day positions count once for activity and both for revenue.
INSERT INTO sales (client_id, purchase_datetime, quantity, total_price) VALUES
    (101, DATE '2023-01-10', 1, 100),
    (101, DATE '2023-01-10', 1, 40),
    (102, DATE '2023-01-20', 1, 200),
    (101, DATE '2023-03-05', 1, 60),
    (101, DATE '2023-07-10', 1, 40),
    (201, DATE '2023-02-05', 1, 80),
    (301, DATE '2023-06-15', 1, 120),
    (301, DATE '2023-07-15', 1, 30),
    (401, DATE '2023-07-01', 1, 900),
    (501, DATE '2023-12-05', 1, 500),
    (101, DATE '2022-12-31', 1, 9999),
    (888, DATE '2024-01-05', 1, 9999),
    (777, DATE '2023-02-10', 0, 9999),
    (778, DATE '2023-02-15', -1, -50),
    (101, DATE '2023-02-10', 0, 9999);
