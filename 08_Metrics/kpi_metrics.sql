use customer_intelligence_db;

with kpi_metrics as(
	select
		coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as total_revenue,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(r.quantity * oi.selling_price) - sum(case when pm.payment_status = "Refunded" then pm.amount else 0 end),2),0) as net_revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as cogs,
        count(distinct o.order_id) as total_orders,
        count(distinct c.cust_id) as total_customers,
        round(count(distinct o.order_id)/ nullif(count(distinct c.cust_id),0),2) as avg_orders_per_customer,
        round(sum(oi.quantity * oi.selling_price) / nullif(count(distinct o.order_id),0),2) as avg_order_value,
        round(sum(oi.quantity * oi.selling_price) / nullif(count(distinct c.cust_id),0),2) as customer_lifetime_value,
        round(100.0 * count(distinct r.return_id) / nullif(count(distinct o.order_id), 0), 2) as return_rate,
        round(100.0 * count(distinct case when pm.payment_status = 'refunded' then pm.payment_id end) / nullif(count(distinct pm.payment_id), 0), 2) as refund_rate,
        round(avg(rv.rating), 2) as avg_rating,
        round(100.0 * (sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price)) / nullif(sum(oi.quantity * oi.selling_price), 0), 2) as profit_margin
	from customers c
    left join orders o on c.cust_id = o.cust_id and o.order_status in ('delivered', 'shipped')
    left join order_items oi on o.order_id = oi.order_id
    left join products p on oi.prod_id = p.prod_id
    left join returns r on oi.order_id = r.order_id and oi.prod_id = r.prod_id
    left join payments pm on o.order_id = pm.order_id
    left join reviews rv on c.cust_id = rv.cust_id
),
best_category as (
    select
        p.category,
        round(sum(oi.quantity * oi.selling_price), 2) as revenue
    from products p
    join order_items oi on p.prod_id = oi.prod_id
    join orders o on oi.order_id = o.order_id
    where o.order_status in ('delivered', 'shipped')
    group by p.category
    order by revenue desc
    limit 1
),
worst_category as (
    select
        p.category,
        round(sum(oi.quantity * oi.selling_price), 2) as revenue
    from products p
    join order_items oi on p.prod_id = oi.prod_id
    join orders o on oi.order_id = o.order_id
    where o.order_status in ('delivered', 'shipped')
    group by p.category
    order by revenue asc
    limit 1
),
top_campaign as (
    select
        mc.campaign_name,
        count(distinct cc.cust_id) as customers_reached,
        count(distinct case when cc.campaign_status = 'purchased' then cc.cust_id end) as conversions
    from marketing_campaigns mc
    left join customer_campaigns cc on mc.campaign_id = cc.campaign_id
    group by mc.campaign_name
    order by conversions desc
    limit 1
),
top_city as (
    select
        c.city,
        round(sum(oi.quantity * oi.selling_price), 2) as revenue
    from customers c
    join orders o on c.cust_id = o.cust_id
    join order_items oi on o.order_id = oi.order_id
    where o.order_status in ('delivered', 'shipped')
    group by c.city
    order by revenue desc
    limit 1
),
top_product as(
	select
        p.prod_name,
        round(sum(oi.quantity * oi.selling_price), 2) as revenue
	from products p
    join order_items oi on p.prod_id = oi.prod_id
    join orders o on oi.order_id = o.order_id
    where o.order_status in ('delivered', 'shipped')
    group by p.prod_name
    order by revenue desc
    limit 1
),
revenue_trend as(
	select
		date_format(o.order_date, "%Y-%m") as month,
        round(sum(oi.quantity * oi.selling_price), 2) as revenue
	from orders o
    join order_items oi on o.order_id = oi.order_id
    where o.order_status in ('delivered', 'shipped')
    group by date_format(o.order_date, '%Y-%m')
    order by month
    limit 6
)
select
	"total revenue" as metric,
    total_revenue as value,
    case
        when total_revenue > 1000000 then 'good'
        when total_revenue > 500000 then 'warning'
        else 'critical'
    end as status
from kpi_metrics
union all
select
	'net revenue',
    net_revenue,
    case
        when net_revenue > 800000 then 'good'
        when net_revenue > 400000 then 'warning'
        else 'critical'
    end
from kpi_metrics
union all
select
    'total orders',
    total_orders,
    case
        when total_orders > 1000 then 'good'
        when total_orders > 500 then 'warning'
        else 'critical'
    end
from kpi_metrics
union all
select
    'total customers',
    total_customers,
    case
        when total_customers > 500 then 'good'
        when total_customers > 200 then 'warning'
        else 'critical'
    end
from kpi_metrics
union all
select
    'average order value',
    avg_order_value,
    case
        when avg_order_value > 2000 then 'good'
        when avg_order_value > 1000 then 'warning'
        else 'critical'
    end
from kpi_metrics
union all
select
    'customer lifetime value',
    customer_lifetime_value,
    case
        when customer_lifetime_value > 5000 then 'good'
        when customer_lifetime_value > 2000 then 'warning'
        else 'critical'
    end
from kpi_metrics
union all
select
    'return rate (%)',
    return_rate,
    case
        when return_rate < 10 then 'good'
        when return_rate < 20 then 'warning'
        else 'critical'
    end
from kpi_metrics
union all
select
    'refund rate (%)',
    refund_rate,
    case
        when refund_rate < 5 then 'good'
        when refund_rate < 10 then 'warning'
        else 'critical'
    end
from kpi_metrics
union all
select
    'avg customer rating',
    avg_rating,
    case
        when avg_rating >= 4.0 then 'good'
        when avg_rating >= 3.0 then 'warning'
        else 'critical'
    end
from kpi_metrics
union all
select
    'profit margin (%)',
    profit_margin,
    case
        when profit_margin >= 20 then 'good'
        when profit_margin >= 10 then 'warning'
        else 'critical'
    end
from kpi_metrics
union all

select
    concat('best category: ', category),
    revenue,
    'good'
from best_category
union all

select
    concat('worst category: ', category),
    revenue,
    'critical'
from worst_category
union all

select
    concat('top campaign: ', campaign_name),
    conversions,
    'good'
from top_campaign
union all

select
    concat('top city: ', city),
    revenue,
    'good'
from top_city
union all

select
    concat('top product: ', prod_name),
    revenue,
    'good'
from top_product
union all

select
    concat('revenue trend (', month, '):'),
    revenue,
    case
        when revenue > lag(revenue) over(order by month) then 'good'
        else 'warning'
    end
from revenue_trend;