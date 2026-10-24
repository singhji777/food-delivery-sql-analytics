-- 10 | Cloud kitchens vs regular restaurants: speed, cancellations and basket size
SELECT CASE WHEN r.is_cloud_kitchen = 1 THEN 'Cloud kitchen' ELSE 'Regular restaurant' END AS kitchen_type,
       COUNT(*)                                                     AS orders,
       ROUND(AVG(o.delivery_minutes), 1)                            AS avg_delivery_min,
       ROUND(100.0 * SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 1) AS cancel_rate_pct,
       ROUND(AVG(o.order_value), 1)                                 AS avg_order_value,
       ROUND(AVG(r.rating), 2)                                      AS avg_rating
FROM orders o JOIN restaurants r ON r.restaurant_id = o.restaurant_id
GROUP BY 1;
