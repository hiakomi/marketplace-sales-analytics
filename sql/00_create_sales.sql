CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    client_id INTEGER,
    gender VARCHAR(1),
    purchase_datetime DATE,
    purchase_time_as_seconds_from_midnight INTEGER,
    product_id INTEGER,
    quantity SMALLINT,
    price_per_item INTEGER,
    discount_per_item INTEGER,
    total_price FLOAT
);
