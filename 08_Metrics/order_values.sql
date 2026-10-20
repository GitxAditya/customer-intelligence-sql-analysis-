use customer_intelligence_db;

with order_values as(
	select
		o.order_id,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as order_value,
        o.order_date,
        date_format(o.order_date, "%Y-%m") as month
	from orders o
    left join order_items oi on o.order_id = oi.order_id
    where o.order_status in ('delivered', 'shipped')
    group by o.order_id, o.order_date
),
ranked_orders as (
    select
        order_value,
        row_number() OVER(order by order_value) as row_num,
        COUNT(*) over() as total_rows
    from order_values
),
median_value as (
    select
        ROUND(avg(order_value), 2) as median_order_value
    from ranked_orders
    where row_num in (
        FLOOR((total_rows + 1) / 2),
        CEIL((total_rows + 1) / 2)
    )
),
aov_metrics as (
    select
        round(avg(order_value), 2) as avg_order_value,
        round(max(order_value), 2) as highest_order_value,
        round(min(order_value), 2) as lowest_order_value,
        round(stddev(order_value), 2) as stddev_order_value,
        COUNT(*) as total_orders,
        round(sum(order_value), 2) as total_revenue
    from order_values
)
select
    am.avg_order_value,
    mv.median_order_value,
    am.highest_order_value,
    am.lowest_order_value,
    am.stddev_order_value,
    am.total_orders,
    am.total_revenue,
    ROUND(am.total_revenue / am.total_orders, 2) as aov_calculation_check
from aov_metrics am
cross join median_value mv;