USE customer_intelligence_db;
with customer_order as (
	select
		c.cust_id,
        c.cust_name,
        c.city,
        c.state,
        count(distinct o.order_id) as total_orders,
        min(o.order_date) as first_order_date,
        max(o.order_date) as last_order_date,
        datediff(max(o.order_date),min(o.order_date)) as days_gap
	from customers c
    inner join orders o on c.cust_id = o.cust_id
     inner join payments p on p.order_id = o.order_id
    where o.order_status in ('Delivered', 'Shipped')
		and p.payment_status = "Success"
	group by c.cust_id, c.cust_name,c.city, c.state
),
frequency_cal as (
	select 
		cust_id,
        cust_name,
        city,
        state,
        total_orders,
        first_order_date,
        last_order_date,
        days_gap,
        case
			when total_orders = 1 then 0
            else round(days_gap/ (total_orders-1),2)
		end as avg_days_between_purchases
	from customer_order
)
select
	cust_id,
	cust_name,
	city,
	state,
	total_orders,
	first_order_date,
	last_order_date,
	days_gap,
    avg_days_between_purchases,
    case
		when  total_orders = 1 then 'New Customer'
        when avg_days_between_purchases <= 30 then 'Frequent Buyer'
        when avg_days_between_purchases <= 60 then 'Moderate Buyer'
        when avg_days_between_purchases <= 90 then 'Occasional Buyer'
        else 'Rare Buyer'
    end as purchase_frequency
from frequency_cal
order by avg_days_between_purchases;