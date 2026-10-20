use customer_intelligence_db;

with return_metrics as (
	select
		count(distinct o.order_id) as total_orders,
        count(distinct r.return_id) as total_returns,
        count(distinct r.prod_id) as products_returned,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as total_revenue,
        coalesce(round(sum(r.quantity * oi.selling_price), 2), 0) as revenue_lost,
        round(100.0 * count(distinct r.return_id) / nullif(count(distinct o.order_id), 0), 2) as return_rate
        
    from orders o
    left join returns r on o.order_id = r.order_id
    left join order_items oi on o.order_id = oi.order_id
    where o.order_status in ('delivered', 'shipped')
),
category_returns as (
	select
		p.category,
        count(distinct r.return_id) as returns_count,
        count(distinct o.order_id) as orders_count,
        round(100* count(distinct r.return_id)/ nullif(count(distinct o.order_id),0),2)  as category_return_rate,
        round(sum(r.quantity * oi.selling_price), 2) as revenue_lost,
        rank() over(order by count(distinct r.retrun_id) desc) as return_rank
    from products p
    left join order_items oi on p.prod_id = oi.prod_id
    left join orders o on oi.order_id = o.order_id
    left join returns r on oi.order_id = r.order_id and oi.prod_id = r.prod_id
    where o.order_status in ('delivered', 'shipped')
    group by p.category
),
return_trend as(
	select
		date_format(r.return_date,"%Y-%m-01") as month,
        count(r.return_id) as monthly_retruns,
        round(100* count(distinct r.return_id) / nullif(count(distinct o.order_id),0),2) as return_rat
        from returns r
    group by date_format(r.return_date, '%Y-%m-01')
)
select
	'return rate' as metric,
    return_rate as value
from return_metrics
union all
select
    'revenue lost',
    revenue_lost
from return_metrics
union all
select
    'products returned',
    products_returned
from return_metrics
union all
select
    'total orders',
    total_orders
from return_metrics;