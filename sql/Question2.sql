-- Qui sont les vendeurs ayant généré un chiffre d'affaires de plus de
-- 100000 Real sur des commandes livrées via Olist ?

SELECT
    oi.seller_id,
    s.seller_city,
    s.seller_state,
    SUM(oi.price + oi.freight_value) AS total_revenue
FROM
    order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id
WHERE
    o.order_status = 'delivered'
GROUP BY
    oi.seller_id
HAVING
    total_revenue > 100000;

   
   