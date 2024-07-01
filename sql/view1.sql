CREATE VIEW customer_segments AS
SELECT
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders,
    AVG(strftime('%s', o.order_delivered_customer_date) - strftime('%s', o.order_purchase_timestamp)) / 86400 AS avg_delivery_time_days,
    MAX(o.order_purchase_timestamp) AS last_order_date,
    (julianday('now') - julianday(MAX(o.order_purchase_timestamp))) AS days_since_last_order,
    SUM(t.total_amount) AS total_spent -- Hypothétique, nécessite une jointure avec une table de transactions
FROM
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
LEFT JOIN
    transactions t ON o.order_id = t.order_id -- Hypothétique, nécessite adaptation
GROUP BY
    c.customer_unique_id;
