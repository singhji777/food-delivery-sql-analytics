-- 01 | Monthly business KPIs: GMV, orders, AOV, cancellation rate, MoM growth
-- Concepts: CTE, conditional aggregation, LAG window function
WITH monthly AS (
    SELECT
        strftime('%Y-%m', order_ts)                                              AS month,
        COUNT(*)                                                                 AS total_orders,
        SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END)                    AS delivered_orders,
        ROUND(100.0 * SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancel_rate_pct,
        ROUND(SUM(CASE WHEN status = 'Delivered' THEN order_value - discount_amount + delivery_fee END), 0) AS net_gmv,
        ROUND(AVG(CASE WHEN status = 'Delivered' THEN order_value END), 1)       AS aov
    FROM orders
    GROUP BY 1
)
SELECT
    month, total_orders, delivered_orders, cancel_rate_pct, net_gmv, aov,
    ROUND(100.0 * (net_gmv - LAG(net_gmv) OVER (ORDER BY month)) / LAG(net_gmv) OVER (ORDER BY month), 1) AS gmv_mom_growth_pct,
    SUM(net_gmv) OVER (ORDER BY month)                                           AS cumulative_gmv
FROM monthly
ORDER BY month;
