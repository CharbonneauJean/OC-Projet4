WITH SellerRevenue AS (
    SELECT
        oi.seller_id,
        SUM(oi.price + oi.freight_value) AS total_revenue,
        COUNT(DISTINCT oi.order_id) AS order_count,
        COUNT(DISTINCT oi.product_id) AS unique_products_sold
    FROM
        order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE
        o.order_status = 'delivered'
    GROUP BY
        oi.seller_id
    HAVING
        total_revenue > 100000
)
SELECT
    sr.seller_id,
    s.seller_city,
    s.seller_state,
    sr.total_revenue,
    sr.order_count,
    sr.unique_products_sold,
    ROUND(sr.total_revenue / sr.order_count, 2) AS average_order_value
FROM
    SellerRevenue sr
JOIN sellers s ON sr.seller_id = s.seller_id
ORDER BY
    sr.total_revenue DESC;