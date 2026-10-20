use customer_intelligence_db;

-- ---------------------------------- Ques18
with aov_analysis as (
	select
		date_format(o.order_date,"%Y-%m-01") as month_date,
        date_format(o.order_date,"%M %Y") as month,
        count(distinct o.order_id) as total_orders,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue,
        sum(oi.quantity * oi.selling_price) / count(distinct o.order_id) as avg_order_value
	from orders o
    inner join order_items oi on o.order_id = oi.order_id
    inner join payments p on o.order_id = p.order_id
    where o.order_status in ('Delivered', 'Shipped')
        and p.payment_status = 'Success'
	group by date_format(o.order_date,"%Y-%m-01"),
        date_format(o.order_date,"%M %Y")
)
select
	month_date,
    month,
    total_orders,
    revenue,
    avg_order_value,
    lag(avg_order_value,1) over(order by month_date) as previous_aov,
    round(
		100* (avg_order_value- lag(avg_order_value,1) over(order by month_date))/
        nullif(lag(avg_order_value,1) over(order by month_date),0),2
    ) as aov_growth_percent
from aov_analysis
order by month_date