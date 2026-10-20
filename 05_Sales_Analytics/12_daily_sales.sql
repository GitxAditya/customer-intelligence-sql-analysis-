use customer_intelligence_db;

-- ---------------------------------------- Q12
with cust_revenue as(
	select
		o.order_date,
		date_format(o.order_date,"%W") as day_name,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue,
        count(distinct o.order_id) as total_orders,
        coalesce(sum(oi.quantity),0) as total_unit_sold
	from orders o
    inner join order_items oi on o.order_id = oi.order_id
    inner join payments p on o.order_id = p.order_id
    where o.order_status in ('Delivered', 'Shipped')
        and p.payment_status = 'Success'
	group by o.order_date
)
select
	order_date,
    day_name,
    revenue,
    total_orders,
    total_unit_sold,
    lag(revenue,1) over(order by order_date) as previous_day_revenue,
    round(
		100* (revenue - lag(revenue,1) over(order by order_date))/
        nullif(lag(revenue,1) over(order by order_date),0),2
    ) as growth_percentage
from cust_revenue 
order by order_date desc