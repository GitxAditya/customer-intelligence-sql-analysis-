USE customer_intelligence_db;
with customer_spending as(
	select
		c.cust_id,
        c.cust_name,
        c.city,
        c.state,
        count(distinct o.order_id) as total_orders,
        round(sum(oi.quantity * oi.selling_price),2) as total_spent,
        round(avg(oi.quantity * oi.selling_price),2) as avg_order_value
	from customers c
    inner join orders o on c.cust_id = o.cust_id
    inner join order_items oi on o.order_id = oi.order_id
    inner join payments p on p.order_id = oi.order_id
    where o.order_status in ('Delivered', 'Shipped')
		and p.payment_status = "Success"
	group by c.cust_id, c.cust_name, c.city, c.state
),
spending_stats as(
	select
		cust_id,
        cust_name,
        city,
        state,
        total_orders,
        total_spent,
        avg_order_value,
        percent_rank() over(order by total_spent desc) as percentile
	from customer_spending
)
select
	cust_id,
	cust_name,
	city,
	state,
	total_orders,
	total_spent,
	avg_order_value,
    case
		when total_spent >= 500000 then 'Platinum'
        when total_spent >= 200000 then 'Gold'
        when total_spent >= 100000 then 'Silver'
        else 'Bronze'
    END AS customer_segment,
    case
        when total_spent >= 500000 then 1
        when total_spent >= 200000 then 2
        when total_spent >= 100000 then 3
        else 4
    end as segment_priority
from spending_stats
 order by segment_priority, total_spent DESC;