-- 08 | Do discounts increase order size or just cost money? And do they change cancellations?
-- Concepts: CASE bucketing, ratio metrics, comparing groups
SELECT
    CASE WHEN discount_amount = 0 THEN '0%'
         WHEN 1.0 * discount_amount / order_value <= 0.10 THEN '1-10%'
         WHEN 1.0 * discount_amount / order_value <= 0.20 THEN '11-20%'
         ELSE '21%+' END                                           AS discount_band,
    COUNT(*)                                                        AS orders,
    ROUND(AVG(order_value), 1)                                      AS avg_order_value,
    ROUND(SUM(discount_amount), 0)                                  AS total_discount_given,
    ROUND(100.0 * SUM(discount_amount) / SUM(order_value), 1)       AS discount_pct_of_gmv,
    ROUND(100.0 * SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 1) AS cancel_rate_pct
FROM orders
GROUP BY 1
ORDER BY MIN(1.0 * discount_amount / order_value);
