USE customer_intelligence_db;
with customer_activity as(
	select
		c.cust_id,
        c.cust_name,
        c.city,
        c.state,
        c.email,
        c.phone,
        max(o.order_date) as last_purchase_date,
        count(distinct o.order_id) as total_orders,
        round(sum(oi.quantity * oi.selling_price),2) as total_revenue,
        datediff(max(o.order_date), min(order_date)) as days_since_last_purchase
	from customers c
    inner join orders o on o.cust_id = c.cust_id
    inner join order_items oi on oi.order_id =  o.order_id
    inner join payments p on p.order_id = o.order_id
    where o.order_status in ('Delivered', 'Shipped')
		and p.payment_status = "Success"
	group by c.city, c.state, c.email,c.phone,c.cust_id,c.cust_name
)
select
	cust_name,
    city,
    state,
    last_purchase_date ,
    days_since_last_purchase,
    total_orders,
    total_revenue,
    case
		when days_since_last_purchase between 180 and 364 then 'Dormant (6-12 months)'
        when days_since_last_purchase >=365 then 'lost(1+ year)'
        else 'active'
	end as dormat_status
from customer_activity
where days_since_last_purchase >= 180
order by days_since_last_purchase DESC;