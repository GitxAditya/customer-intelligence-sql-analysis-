use customer_intelligence_db;

with customer_summary as (
    select
        c.cust_id,
        count(distinct o.order_id) as order_count,
        min(o.order_date) as first_order_date,
        max(o.order_date) as last_order_date,
        coalesce(sum(oi.quantity * oi.selling_price), 0) as total_spent
    from customers c
    left join orders o on c.cust_id = o.cust_id
    left join order_items oi on o.order_id = oi.order_id
    where o.order_status in ('delivered', 'shipped')
    group by c.cust_id
),
customer_metrics as (
    select
        count(*) as total_customers,
        sum(case 
            when datediff(curdate(), last_order_date) <= 30 
            then 1 else 0 
        end) as active_customers,
        sum(case 
            when datediff(curdate(), first_order_date) <= 30 
            then 1 else 0 
        end) as new_customers,
        sum(case 
            when order_count > 1 
            then 1 else 0 
        end) as repeat_customers,
        sum(case 
            when datediff(curdate(), last_order_date) between 90 and 180 
            then 1 else 0 
        end) as dormant_customers,
        sum(case 
            when datediff(curdate(), last_order_date) > 180 
            then 1 else 0 
        end) as churned_customers,
        sum(order_count) as total_orders,
        round(sum(total_spent), 2) as total_revenue
    from customer_summary
)
select
    total_customers,
    active_customers,
    new_customers,
    repeat_customers,
    dormant_customers,
    churned_customers,
    round(100.0 * active_customers / nullif(total_customers, 0), 2) as active_rate,
    round(100.0 * repeat_customers / nullif(total_customers, 0), 2) as repeat_rate,
    round(100.0 * churned_customers / nullif(total_customers, 0), 2) as churn_rate,
    round(total_orders / nullif(total_customers, 0), 2) as avg_orders_per_customer,
    round(total_revenue / nullif(total_customers, 0), 2) as avg_revenue_per_customer
from customer_metrics;