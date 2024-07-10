-- Quels sont les 5 codes postaux, enregistrant plus de 30 reviews,
-- avec le pire review score moyen sur les 12 derniers mois ?
WITH LastOrderDate AS (
    SELECT MAX(order_purchase_timestamp) AS max_date
    FROM orders
),
ReviewedOrders AS (
    SELECT
        c.customer_zip_code_prefix,
        g.geolocation_city,
        r.review_score,
        r.review_id
    FROM
        orders o
        JOIN customers c ON o.customer_id = c.customer_id
        JOIN order_reviews r ON o.order_id = r.order_id
        LEFT JOIN geoloc g ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
        CROSS JOIN LastOrderDate
    WHERE
        o.order_purchase_timestamp >= DATE(LastOrderDate.max_date, '-12 month')
),
ReviewCountAndAverageScore AS (
    SELECT
        customer_zip_code_prefix,
        MAX(geolocation_city) AS city,
        COUNT(review_id) AS review_count,
        AVG(review_score) AS average_review_score
    FROM
        ReviewedOrders
    GROUP BY
        customer_zip_code_prefix
    HAVING
        review_count > 30
)
SELECT
    customer_zip_code_prefix,
    city,
    review_count,
    ROUND(average_review_score, 2) AS average_review_score
FROM
    ReviewCountAndAverageScore
ORDER BY
    average_review_score ASC,
    review_count DESC
LIMIT 5;