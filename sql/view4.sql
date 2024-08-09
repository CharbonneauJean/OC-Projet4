CREATE VIEW customer_segments3 AS
WITH last_order AS (
    SELECT 
        customer_id,
        order_id,
        order_status,
        order_purchase_timestamp,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_purchase_timestamp DESC) AS rn
    FROM orders
),
last_payment AS (
    SELECT
        o.customer_id,
        op.payment_type,
        op.payment_installments,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_purchase_timestamp DESC) AS rn
    FROM orders o
    JOIN order_pymts op ON o.order_id = op.order_id
)
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    AVG(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_purchase_timestamp)) AS avg_delivery_time_days,
    MAX(o.order_purchase_timestamp) AS last_order_date,
    (JULIANDAY('2018-10-17 18:30:18') - JULIANDAY(MAX(o.order_purchase_timestamp))) AS days_since_last_order,
    SUM(oi.price + oi.freight_value) AS total_spent,
    AVG(r.review_score) AS avg_review_score,
    AVG(CASE 
        WHEN JULIANDAY(o.order_delivered_customer_date) > JULIANDAY(o.order_estimated_delivery_date) 
        THEN JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_estimated_delivery_date)
        ELSE 0 
    END) AS avg_delivery_delay_days,
    MAX(CASE 
        WHEN JULIANDAY(o.order_delivered_customer_date) > JULIANDAY(o.order_estimated_delivery_date) 
        THEN JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_estimated_delivery_date)
        ELSE 0 
    END) AS max_delivery_delay_days,
    lo.order_status AS last_order_status,
    CASE WHEN MAX(COALESCE(LENGTH(r.review_comment_message), 0)) > 0 THEN 1 ELSE 0 END AS has_comment,
    lp.payment_type AS last_payment_type,
    lp.payment_installments AS last_payment_installments
FROM
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
LEFT JOIN
    order_items oi ON o.order_id = oi.order_id
LEFT JOIN
    order_reviews r ON o.order_id = r.order_id
LEFT JOIN
    last_order lo ON c.customer_id = lo.customer_id AND lo.rn = 1
LEFT JOIN
    last_payment lp ON c.customer_id = lp.customer_id AND lp.rn = 1
WHERE
    oi.price IS NOT NULL 
GROUP BY
    c.customer_unique_id, lo.order_status, lp.payment_type, lp.payment_installments;