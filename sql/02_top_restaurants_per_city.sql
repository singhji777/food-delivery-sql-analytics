-- 02 | Top 3 restaurants by revenue in every city
-- Concepts: JOIN, RANK() OVER (PARTITION BY ...), subquery filtering on window result
SELECT city, rank_in_city, restaurant_name, cuisine, rating, orders, revenue
FROM (
    SELECT
        r.city, r.restaurant_name, r.cuisine, r.rating,
        COUNT(*)                                                       AS orders,
        ROUND(SUM(o.order_value - o.discount_amount), 0)               AS revenue,
        RANK() OVER (PARTITION BY r.city ORDER BY SUM(o.order_value - o.discount_amount) DESC) AS rank_in_city
    FROM orders o
    JOIN restaurants r ON r.restaurant_id = o.restaurant_id
    WHERE o.status = 'Delivered'
    GROUP BY r.restaurant_id
)
WHERE rank_in_city <= 3
ORDER BY city, rank_in_city;
