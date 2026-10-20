with customer_activity as(
	select
		c.cust_id,
        c.cust_name,
        c.city,
        c.email,
        max(o.order_date) as last_purchase_date,
        count(distinct o.order_id) as total_orders,
        round(sum(oi.quantity * oi.selling_price),2) as total_revenue,
        datediff(curdate(),max(o.order_date)) as days_since_last_purchase
	from customers c
    inner join orders o on o.cust_id = c.cust_id
    inner join order_items oi on oi.order_id =  o.order_id
    inner join payments p on p.order_id = o.order_id
    where o.order_status in ('Delivered', 'Shipped')
		and p.payment_status = "Success"
	group by c.city, c.email,c.cust_id,c.cust_name
)
    SELECT
        cust_id,
        cust_name,
        city,
        email,
        total_orders,
        total_revenue,
        last_purchase_date,
        days_since_last_purchase,
        case
			when days_since_last_purchase >= 180 and total_orders <= 2 then 'High Risk'
			when days_since_last_purchase >= 90 or total_orders <= 3 then 'Medium Risk'
			else 'Low Risk'
		end as churn_risk_category
	from customer_activity
	where days_since_last_purchase >= 90
	order by days_since_last_purchase desc