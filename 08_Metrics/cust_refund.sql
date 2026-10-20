use customer_intelligence_db;

with cust_refund as (
	select
		count(distinct case when p.payment_status = "Refunded" then p.payment_id end) as refund_orders,
        round(sum(case when p.payment_status = "Refunded" then p.amount else 0 end),2) as revenue_lost,
        count(distinct o.order_id) as total_orders,
        coalesce(round(sum(p.amount), 2), 0) as total_revenue
	from payments p
	left join orders o on p.order_id = o.order_id
    where o.order_status in ('delivered', 'shipped', 'returned')
),
re_percent as(
	select
		refund_orders,
        revenue_lost,
        total_orders,
        total_revenue,
        round(100* revenue_lost/ nullif(total_revenue,0),2) as Refund_Percentage,
        round(100* refund_orders/ nullif(total_orders,0),2) as Refund_Rate
	from cust_refund
),
re_category as(
	select
		p.category,
        count(distinct pm.payment_id) as refund_count,
        coalesce(round(sum(pm.amount), 2), 0) as refund_amount
	from products p
    join order_items oi on p.prod_id = oi.prod_id
    join orders o on oi.order_id = o.order_id
    join payments pm on o.order_id = pm.order_id
    where pm.payment_status = 'refunded'
    group by p.category
    order by refund_amount desc
),
pay_refund as(
	select
		payment_method,
        count(distinct payment_id) as refund_count,
        coalesce(round(sum(amount), 2), 0) as refund_amount
	from payments
    where payment_status = 'refunded'
    group by payment_method
    order by refund_amount desc
)
select
	'refund amount' as metric,
    revenue_lost as value
from cust_refund
union all
select
	'Refund Percentage',
    Refund_Percentage
from re_percent
union all
select
	'Revenue lost',
    revenue_lost
from cust_refund;

select
	category,
    refund_count,
    refund_amount
from re_category
where refund_count> 0
order by refund_amount desc;

select
	payment_method,
    refund_count,
    refund_amount
from pay_refund
where refund_count > 0
order by refund_amount desc;