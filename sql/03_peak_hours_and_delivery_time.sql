-- 03 | Demand and service quality by hour of day
-- Concepts: strftime date parts, conditional aggregation, ratios
SELECT
    CAST(strftime('%H', order_ts) AS INTEGER)                                   AS hour,
    COUNT(*)                                                                    AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)                          AS pct_of_orders,
    ROUND(AVG(delivery_minutes), 1)                                             AS avg_delivery_min,
    ROUND(100.0 * SUM(CASE WHEN delivery_minutes > 45 THEN 1 ELSE 0 END) / SUM(CASE WHEN status <> 'Cancelled' THEN 1 ELSE 0 END), 1) AS pct_over_45min,
    ROUND(100.0 * SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 1) AS cancel_rate_pct
FROM orders
GROUP BY 1
ORDER BY 1;
