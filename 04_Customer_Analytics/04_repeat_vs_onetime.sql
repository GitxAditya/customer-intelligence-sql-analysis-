with customer_order_count as(
	select
		c.cust_id,
        c.cust_name,
        count(distinct o.order_id) as total_orders,
        round(sum(oi.quantity * oi.selling_price),2) as total_spent,
        min(o.order_date) as first_order_date,
		max(o.order_date) as last_order_date
	from customers c
    inner join orders o on o.cust_id = c.cust_id
    inner join order_items oi on oi.order_id = o.order_id
    inner join payments p on o.order_id = p.order_id
    where  o.order_status IN ('Delivered', 'Shipped') and
		p.payment_status = "Success"
    group by c.cust_id, c.cust_name
),
customer_segment as(
	select
		cust_id,
        cust_name,
        total_orders,
        total_spent,
        first_order_date,
        last_order_date,
        case
			when total_orders >= 2 then "Repeat Customer"
            else "One time buyer"
		end as customer_type
		from customer_order_count
)
select
	customer_type,
    count(*) as customer_count,
    round(100* count(*)/ sum(count(*)) over(), 2) as percentage,
    round(avg(total_spent),2) as avg_spent,
    round(sum(total_spent),2) as total_revenue,
    round(avg(total_orders),2) as avg_orders
from customer_segment
group by customer_type
order by customer_count desc