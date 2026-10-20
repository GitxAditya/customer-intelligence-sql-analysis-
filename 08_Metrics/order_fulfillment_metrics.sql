use customer_intelligence_db;

with order_metrics as(
	select
		count(distinct o.order_id) as total_orders,
        count(distinct case when o.order_status = 'delivered' then o.order_id end) as delivered_orders, 
        count(distinct case when o.order_status = 'shipped' then o.order_id end) as shipped_orders,
        count(distinct case when o.order_status = 'cancelled'  then o.order_id end) as cancelled_orders,
        count(distinct case when o.order_status = 'pending'  then o.order_id end) as pending_orders,
        count(distinct case when o.order_status in ('delivered', 'shipped') then o.order_id end) as successful_orders,
        count(distinct
			case when o.order_date = curdate()
            then o.order_id 
        end) as orders_today,
        count(distinct
			case when date_format(o.order_date, "%Y-%m") = date_format(curdate(),"%Y-%m")
            then o.order_id
        end) as orders_this_month,
        count(distinct c.cust_id) as total_customers
    from customers c
    left join orders o on c.cust_id = o.cust_id
    where o.order_status is not null
) 
select
    total_orders,
    delivered_orders,
    shipped_orders,
    cancelled_orders,
    pending_orders,
    successful_orders,
    round(100* successful_orders/nullif(total_orders,0),2) as order_success_rate,
    round(total_orders / nullif(total_customers,0),2) as avg_orders_per_customer,
    orders_today,
    orders_this_month
from order_metrics;
