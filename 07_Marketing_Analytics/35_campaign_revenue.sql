use customer_intelligence_db;

-- ------------------------------------------------Ques 35
with campaign_revenue as (
    select
        mc.campaign_id,
        mc.campaign_name,
        mc.campaign_type,
        mc.budget,
        count(distinct o.order_id) as total_orders,
        count(distinct cc.cust_id) as customers_reached,
        count(distinct case when cc.campaign_status = 'Purchased' then cc.cust_id end) as customers_converted,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue,
        round(sum(oi.quantity*oi.selling_price) / count(distinct o.order_id),2) as avg_order_value
	from marketing_campaigns mc
    left join customer_campaigns cc on mc.campaign_id = cc.campaign_id
    left join customers c on cc.cust_id = c.cust_id
    left join orders o on c.cust_id = o.cust_id
    left join order_items oi on o.order_id = oi.order_id
    where o.order_status in ('Delivered', 'Shipped') or o.order_status is null
    group by mc.campaign_id, mc.campaign_name, mc.campaign_type, mc.budget
)
select
	rank() over(order by revenue desc) as revenue_rank,
	campaign_name,
    campaign_type,
    budget,
    customers_reached,
    customers_converted,
    total_orders,
    revenue,
    avg_order_value,
    round(100*revenue /sum(revenue) over(),2) as revenue_percent,
    round(100.0 * customers_converted / nullif(customers_reached, 0), 2) AS conversion_rate,
    round(revenue / nullif(budget, 0), 2) AS revenue_per_budget
from campaign_revenue
where budget >0
order by revenue_rank;