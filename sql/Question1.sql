-- En excluant les commandes annulées, quelles sont les commandes
-- récentes de moins de 3 mois que les clients ont reçues avec au moins 3
-- jours de retard ?
WITH LastOrderDate AS (
    SELECT MAX(order_purchase_timestamp) AS max_date
    FROM orders
)
SELECT 
    o.order_id, 
    o.customer_id,
    c.customer_city,
    c.customer_state, 
    o.order_purchase_timestamp, 
    o.order_delivered_customer_date, 
    o.order_estimated_delivery_date,
    JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_estimated_delivery_date) AS days_late
FROM 
    orders o
JOIN customers c ON o.customer_id = c.customer_id
CROSS JOIN LastOrderDate
WHERE 
    o.order_status != 'canceled'
    AND o.order_purchase_timestamp >= DATE(LastOrderDate.max_date, '-3 month')
    AND o.order_delivered_customer_date > o.order_estimated_delivery_date
    AND JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_estimated_delivery_date) >= 3
ORDER BY 
    days_late DESC, o.order_purchase_timestamp DESC;