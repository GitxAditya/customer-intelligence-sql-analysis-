use customer_intelligence_db;

-- -----------------------------------------------Q14
with seasonal_sales as (
	select
		o.order_id,
        o.order_date,
        quarter(o.order_date) as quarter,
        year(o.order_date) as year,
        oi.quantity * oi.selling_price as order_amount
	from orders o
    inner join order_items oi on o.order_id = oi.order_id
    inner join payments p on o.order_id = p.order_id
    where o.order_status in ('Delivered', 'Shipped')
        and p.payment_status = 'Success'
)
select
	concat('Q', quarter,' ' , year) as quarter,
    case
		when quarter = 1 then 'Winter'
        when quarter = 2 then 'Spring'
        when quarter = 3 then 'Summer'
        when quarter = 4 then 'Fall'
    end as season,
    count(distinct order_id) as total_orders,
    round(sum(order_amount),2) as revenue,
    round(avg(order_amount),2) as avg_order_value,
    round(sum(order_amount) / (select sum(order_amount) from seasonal_sales) * 100, 2) as revenue_percentage
from seasonal_sales
group by year, quarter
order by year, quarter