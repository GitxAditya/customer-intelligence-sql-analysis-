use customer_intelligence_db;

with revenue_metrics as (
    select
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as gross_revenue,
		coalesce(round(sum(r.quantity * oi.selling_price), 2), 0) as returns_deduction,
        coalesce(round(sum(case when pm.payment_status = "refunded" then pm.amount else 0 end),2),0) as refunds_deduction,
		coalesce(round(sum(oi.quantity* (p.price- oi.selling_price)),2),0) as discounts_deduction,
		coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as cogs,
		coalesce(round(
            sum(oi.quantity * oi.selling_price)
            - sum(r.quantity * oi.selling_price)
            - sum(case when pm.payment_status = 'refunded' then pm.amount else 0 end)
            - sum(oi.quantity * (p.price - oi.selling_price))
        , 2), 0) as net_revenue
	from order_items oi
    join orders o on oi.order_id = o.order_id
    join products p on oi.prod_id = p.prod_id
    left join returns r on oi.order_id = r.order_id and oi.prod_id = r.prod_id
    left join payments pm on o.order_id = pm.order_id
    where o.order_status in ('delivered', 'shipped')
)
select
    gross_revenue,
    returns_deduction,
    refunds_deduction,
    discounts_deduction,
    cogs,
    net_revenue,
    round(gross_revenue - cogs,2) as gross_profit,
    round(net_revenue - cogs, 2) as net_profit,
    round(100.0 * (gross_revenue - cogs) / nullif(gross_revenue, 0), 2) as gross_margin_percent,
    round(100.0 * (net_revenue - cogs) / nullif(net_revenue, 0), 2) as net_margin_percent
from revenue_metrics;