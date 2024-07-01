-- Permet d'obtenir la dernière date de commande du jeu de données
select o.order_purchase_timestamp  from orders o order by o.order_purchase_timestamp desc



-- Qui sont les nouveaux vendeurs (moins de 3 mois d'ancienneté) qui
-- sont déjà très engagés avec la plateforme (ayant déjà vendu plus de 30
-- produits) ?
SELECT
    oi.seller_id,
    s.seller_city,
    MIN(o.order_purchase_timestamp) AS first_order_date,
    COUNT(oi.order_id) AS total_sold_products
FROM
    order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id 
GROUP BY
    oi.seller_id
HAVING
    first_order_date >= date('2018-10-17 18:30:18', '-3 month')
    AND total_sold_products > 30;
