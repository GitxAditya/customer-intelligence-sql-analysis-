with customer_revenue as (
	select
		c.city,
        c.state,
        count(distinct c.cust_id) as total_customer,
        count(distinct o.order_id) as total_orders,
        count(distinct oi.item_id) as total_item_sold,
        sum(oi.quantity) as total_unit_sold,
        round(sum(oi.quantity * oi.selling_price),2) as total_revenue,
		round(avg(oi.quantity * oi.selling_price),2) as avg_order_value,
		round(sum(oi.quantity * oi.selling_price)/ count(distinct c.cust_id),2) as revenue_per_customer
	from customers c
    inner join orders o on o.cust_id = c.cust_id
    inner join order_items oi on oi.order_id =  o.order_id
    inner join payments p on p.order_id = o.order_id
    where o.order_status in ('Delivered', 'Shipped')
		and p.payment_status = "Success"
	group by c.city, c.state
)
select
	rank() over(order by total_revenue desc) as city_rank,
    city,
    state,
    total_customer,
    total_orders,
    total_item_sold,
    total_unit_sold,
    total_revenue,
    avg_order_value,
	revenue_per_customer,
    round(100* total_revenue/ sum(total_revenue) over() ,2) as revenue_share_percentage
from customer_revenue
order by city_rank