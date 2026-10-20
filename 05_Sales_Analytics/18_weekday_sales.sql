use customer_intelligence_db;

-- ------------------------------------------------------ques19
with weekday_sales as(
	select
		dayname(o.order_date) as weekday_name,
        dayofweek(o.order_date) as weekday_number,
        count(distinct o.order_id) as total_orders,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as total_revenue
	from orders o
    inner join order_items oi on o.order_id = oi.order_id
    inner join payments p on o.order_id = p.order_id
    where o.order_status in ('Delivered', 'Shipped')
        and p.payment_status = 'Success'
	group by dayname(o.order_date), dayofweek(o.order_date)
)
select
	weekday_name,
    total_orders,
    total_revenue,
    rank() over(order by total_revenue desc) as revenue_rank,
    round(100* total_revenue / sum(total_revenue) over(),2) as revenue_percentage
from weekday_sales
order by revenue_rank