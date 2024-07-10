-- Qui sont les nouveaux vendeurs (moins de 3 mois d'ancienneté) qui
-- sont déjà très engagés avec la plateforme (ayant déjà vendu plus de 30
-- produits) ?
WITH LastOrderDate AS (
    SELECT MAX(order_purchase_timestamp) AS max_date
    FROM orders
),
NewSellersSales AS (
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
)
SELECT
    seller_id,
    seller_city,
    first_order_date,
    total_sold_products
FROM
    NewSellersSales, LastOrderDate
WHERE
    first_order_date >= date(LastOrderDate.max_date, '-3 month')
    AND total_sold_products > 30
ORDER BY
    total_sold_products DESC;