use customer_intelligence_db;

with historical_clv as (
    select
        c.cust_id,
        c.cust_name,
        c.city,
        c.state,
        date_format(min(o.order_date), '%Y-%m-%d') as first_purchase_date,
        date_format(max(o.order_date), '%Y-%m-%d') as last_purchase_date,
        datediff(curdate(), min(o.order_date)) / 365.0 as customer_lifetime_years,
        count(distinct o.order_id) as total_orders,
        count(distinct oi.item_id) as total_items,
        sum(oi.quantity) as total_units,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as total_revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as total_cost,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price),2),0) as total_profit,
		round(count(distinct o.order_id) / nullif(datediff(curdate(), min(o.order_date)) / 30.0, 0), 2) as purchase_frequency_per_month,
        round(sum(oi.quantity) / nullif(count(distinct o.order_id), 0), 2) as avg_basket_size,
        round(sum(oi.quantity * oi.selling_price) / nullif(count(distinct o.order_id), 0), 2) as avg_order_value,
        round(datediff(max(o.order_date), min(o.order_date)) / nullif(count(distinct o.order_id) - 1, 0), 0) as avg_days_between_orders
	from customers c
    left join orders o on c.cust_id = o.cust_id
    left join order_items oi on o.order_id = oi.order_id
    left join products p on oi.prod_id = p.prod_id
    where o.order_status in ('delivered', 'shipped')
    group by c.cust_id, c.cust_name, c.city, c.state
    having total_orders > 0
),
clv_category as (
    select
        *,
        round(total_revenue / nullif(customer_lifetime_years, 0), 2) as annual_clv,
        case
            when total_revenue >= 500000 then 'vip'
            when total_revenue >= 200000 then 'gold'
            when total_revenue >= 100000 then 'silver'
            else 'bronze'
        end as clv_category
    from historical_clv
)
select
    cust_id,
    cust_name,
    city,
    state,
    total_revenue,
    total_profit,
    round(total_profit / nullif(total_revenue, 0) * 100, 2) as profit_margin,
    customer_lifetime_years,
    total_orders,
    purchase_frequency_per_month,
    avg_basket_size,
    avg_order_value,
    first_purchase_date,
    last_purchase_date,
    clv_category,
    case
        when clv_category = 'vip' then 'highest value'
        when clv_category = 'gold' then 'high value'
        when clv_category = 'silver' then 'medium value'
        else 'low value'
    end as priority
from clv_category
order by total_revenue desc;