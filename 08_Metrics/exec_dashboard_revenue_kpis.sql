use customer_intelligence_db;

with revenue_metrics as(
	select
		coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as total_revenue,
        coalesce(round(sum(case when o.order_status = 'delivered' then oi.quantity * oi.selling_price else 0 end),2),0) as delivered_revenue,
        coalesce(round(sum(case when o.order_status = 'shipped' then oi.quantity * oi.selling_price else 0 end),2),0) as shipped_revenue,
        coalesce(round(sum(case when o.order_status in ('delivered', 'shipped') then oi.quantity * oi.selling_price else 0 end),2),0) as successful_revenue,
        coalesce(round(sum(case when o.order_status = 'cancelled' then oi.quantity * oi.selling_price else 0 end),2),0) as cancelled_revenue,
        coalesce(round(sum(
				case when date_format(o.order_date,"%Y-%m") = date_format(curdate(),"%Y-%m")
                then oi.quantity * oi.selling_price else 0 end
            ),2),0) as  revenue_this_month,
         coalesce(round(sum(
				case when date_format(o.order_date,"%Y-%m") = date_format(date_sub(curdate(),interval 1 month), "%Y-%m")
                then oi.quantity * oi.selling_price else 0 end
            ),2),0) as revenue_last_month,
		count(distinct o.order_id) as total_orders,
        count(distinct c.cust_id) as total_customers,
        count(distinct case when o.order_status in ('delivered', 'shipped') then c.cust_id end) as successful_orders
	from customers c
    left join orders o on c.cust_id = o.cust_id
    left join order_items oi on o.order_id = oi.order_id
    left join payments p on o.order_id = p.order_id
        and p.payment_status = 'success'
    where o.order_status is not null
)
select
    total_revenue,
    successful_revenue,
    cancelled_revenue,
    delivered_revenue,
    revenue_this_month,
    revenue_last_month,
    round(100* (revenue_this_month - revenue_last_month)/ nullif(revenue_last_month,0),2) as mom_growth_percent,
    round(total_revenue/ nullif(total_customers, 0),2) as revenue_per_customer,
    round( total_revenue/ nullif(total_orders,0),2) as revenue_per_order
from revenue_metrics;
