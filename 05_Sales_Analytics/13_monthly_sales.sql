use customer_intelligence_db;

-- ----------------------------------Q13
with monthly_revenue as (
	select
		date_format(o.order_date,"%Y-%m-01") as month_date,
        date_format(o.order_date,"%M %Y") as month,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue,
        count(distinct o.order_id) as total_orders,
        coalesce(sum(oi.quantity),0) as total_unit_sold
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
    revenue,
    total_orders,
    total_unit_sold,
    round(
		100*(revenue - lag(revenue,1) over(order by month_date))/
        nullif(lag(revenue,1) over(order by month_date),0),2
        ) as growth_percentage,
	case
        when revenue > lag(revenue, 1) over(order by month_date) then 'Growth'
        when revenue < lag(revenue, 1) over(order by month_date) then 'Decline'
        else 'Flat'
    end as trend
from monthly_revenue
order by month_date;
