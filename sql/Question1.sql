
-- Permet d'obtenir la dernière date de commande du jeu de données
select o.order_purchase_timestamp  from orders o order by o.order_purchase_timestamp desc

-- En excluant les commandes annulées, quelles sont les commandes
-- récentes de moins de 3 mois que les clients ont reçues avec au moins 3
-- jours de retard ?
SELECT o.order_id, o.customer_id, o.order_purchase_timestamp, o.order_delivered_customer_date, o.order_estimated_delivery_date
FROM orders o
WHERE o.order_status != 'canceled'
AND o.order_purchase_timestamp >= date('2018-10-17 18:30:18', '-3 month') -- dernière date de commande
AND o.order_delivered_customer_date > o.order_estimated_delivery_date
AND julianday(o.order_delivered_customer_date) - julianday(o.order_estimated_delivery_date) >= 3;
