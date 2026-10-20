USE customer_intelligence_db;
with customer_spending as(
	select
		c.cust_name,
        count(distinct o.order_id) as total_orders,
        sum(oi.quantity) as total_units,
        round(sum(oi.quantity * oi.selling_price),2) as total_revenue,
        round(avg(oi.quantity * oi.selling_price),2) as avg_order_value,
        max(o.order_date) as last_purchased_date
	from customers c
    inner join orders o on c.cust_id = o.cust_id
    inner join order_items oi on o.order_id = oi.order_id
    inner join payments p on p.order_id = oi.order_id
    where o.order_status in ('Delivered', 'Shipped')
		and p.payment_status = "Success"
	group by c.cust_id, c.cust_name
)
select
	rank() over(order by total_revenue desc) as customer_rank,
	cust_name as customer_name,
    total_orders,
    total_units,
    total_revenue,
    avg_order_value,
    last_purchased_date,
    case
		when total_revenue >= 500000 then "VIP"
        when total_revenue >= 200000 then "High Value"
        when total_revenue >= 100000 then "Medium Value"
        else "Regular"
	end as customer_segment
from customer_spending
limit 20;
