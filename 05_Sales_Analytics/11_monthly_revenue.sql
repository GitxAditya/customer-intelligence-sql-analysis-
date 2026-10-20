use customer_intelligence_db;

-- ----------------------------------Q11
with daily_revenue as(
	select
		date_format(o.order_date, "%Y-%m-01") as month_date,
        date_format(o.order_date, "%Y-%m") as month,
        count(distinct o.order_id) as total_orders,
        sum(oi.quantity) as unit_sold,
        round(sum(oi.quantity*oi.selling_price),2) as revenue
	from orders o
    inner join order_items oi on oi.order_id = o.order_id
    inner join payments p on o.order_id = p.order_id
    where o.order_status in ('Delivered', 'Shipped')
        and p.payment_status = 'Success'
    group by DATE_FORMAT(o.order_date, '%Y-%m-01'), DATE_FORMAT(o.order_date, '%Y-%m')
)
select
	month_date,
    month,
    total_orders,
    unit_sold,
    revenue,
    round(sum(revenue) over(order by month_date),2) as running_revenue,
    round(100* (revenue - lag(revenue,1) over(order by month_date)) / nullif(lag(revenue,1) over(order by month_date),0),2) as revenue_growth_percent
from daily_revenue
order by month_date