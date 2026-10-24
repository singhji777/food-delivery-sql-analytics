-- 09 | Cuisine performance: revenue, AOV, rating, and cuisines worth expanding (HAVING filter)
-- Concepts: multi-table JOIN, GROUP BY + HAVING, window share of total
SELECT r.cuisine,
       COUNT(DISTINCT r.restaurant_id)                                   AS restaurants,
       COUNT(*)                                                          AS orders,
       ROUND(SUM(o.order_value - o.discount_amount), 0)                  AS revenue,
       ROUND(100.0 * SUM(o.order_value - o.discount_amount) / SUM(SUM(o.order_value - o.discount_amount)) OVER (), 1) AS revenue_share_pct,
       ROUND(1.0 * COUNT(*) / COUNT(DISTINCT r.restaurant_id), 0)        AS orders_per_restaurant,
       ROUND(AVG(r.rating), 2)                                           AS avg_rating
FROM orders o JOIN restaurants r ON r.restaurant_id = o.restaurant_id
WHERE o.status = 'Delivered'
GROUP BY r.cuisine
HAVING COUNT(*) > 300
ORDER BY revenue DESC;
