with customer_orders as(
	select
		c.cust_id,
        c.cust_name,
        count(distinct o.order_id) as total_orders,
        min(o.order_date) as first_order_date,
        max(o.order_date) as last_order_date,
        datediff(max(o.order_date),min(o.order_date)) as days_gap
	from customers c
    inner join orders o on c.cust_id = o.cust_id
     inner join payments p on p.order_id = o.order_id
    where o.order_status in ('Delivered', 'Shipped')
		and p.payment_status = "Success"
	group by c.cust_id, c.cust_name
)
select
	case
		when total_orders >= 2 then "Returned Customer"
		else "Never Returned"
	end as customer_type,
    count(*) as customer_count,
    round(100* count(*)/ sum(count(*)) over(), 2) as percentage,
    round(avg(total_orders),2) as avg_orders
from customer_orders 
group by customer_type