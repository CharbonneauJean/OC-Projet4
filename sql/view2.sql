CREATE VIEW customer_segments2 AS
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    AVG(julianday(o.order_delivered_customer_date) - julianday(o.order_purchase_timestamp)) AS avg_delivery_time_days,
    MAX(o.order_purchase_timestamp) AS last_order_date,
    (julianday('2018-10-17 18:30:18') - julianday(MAX(o.order_purchase_timestamp))) AS days_since_last_order,
    SUM(oi.price + oi.freight_value) AS total_spent,
    AVG(r.review_score) AS avg_review_score,
    SUM(p.payment_value) AS total_payments_received
FROM
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
LEFT JOIN
    order_items oi ON o.order_id = oi.order_id
LEFT JOIN
    order_reviews r ON o.order_id = r.order_id
LEFT JOIN
    order_pymts p ON o.order_id = p.order_id
GROUP BY
    c.customer_unique_id;
