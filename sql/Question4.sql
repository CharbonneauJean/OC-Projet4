-- Permet d'obtenir la dernière date de commande du jeu de données
select o.order_purchase_timestamp  from orders o order by o.order_purchase_timestamp desc


-- Quels sont les 5 codes postaux, enregistrant plus de 30 commandes,
-- avec le pire review score moyen sur les 12 derniers mois ?

WITH ReviewedOrders AS (
    SELECT
        c.customer_zip_code_prefix,
        r.review_score,
        o.order_id
    FROM
        orders o
        JOIN customers c ON o.customer_id = c.customer_id
        JOIN order_reviews r ON o.order_id = r.order_id
    WHERE
        o.order_purchase_timestamp >= DATE('2018-10-17 18:30:18', '-12 month')
),

OrderCountAndAverageReview AS (
    SELECT
        customer_zip_code_prefix,
        COUNT(order_id) AS order_count,
        AVG(review_score) AS average_review_score
    FROM
        ReviewedOrders
    GROUP BY
        customer_zip_code_prefix
    HAVING
        order_count > 30
)

SELECT
    customer_zip_code_prefix,
    order_count,
    average_review_score
FROM
    OrderCountAndAverageReview
ORDER BY
    average_review_score ASC,
    order_count DESC
LIMIT 5;
