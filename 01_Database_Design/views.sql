USE customer_intelligence_db;
-- -------------------------------------------------------- VIEWS
create view vw_customer_summary as
with customer_orders as (
	select
		c.cust_id,
        c.cust_name,
        count(distinct o.order_id) as total_orders,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as total_revenue,
        max(o.order_date) as last_order_date
    from customers c
    left join orders o on c.cust_id = o.cust_id
        and o.order_status in ('delivered', 'shipped')
    left join order_items oi on o.order_id = oi.order_id
    group by c.cust_id, c.cust_name
)
select
	cust_id,
    cust_name,
    total_orders,
    total_revenue,
    case
        when total_orders = 0 then 0
        else round(total_revenue / total_orders, 2)
    end as avg_order_value,
    last_order_date
from customer_orders;

-- ---------------------------------------------------2 
create view vw_product_summary as 
with product_metrics as (
	select
		p.prod_id,
        p.prod_name,
        p.category,
        coalesce(round(sum(oi.quantity), 0), 0) as units_sold,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as cost,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as profit
    from orders o
	join order_items oi on o.order_id = oi.order_id
	join products p on oi.prod_id = p.prod_id
		WHERE o.order_status in ('delivered', 'shipped')
    group by p.prod_id, p.prod_name, p.category
)
select
    prod_id,
    prod_name,
    category,
    units_sold,
    revenue,
    profit,
    case
        when revenue = 0 then 0
        else round(100.0 * profit / revenue, 2)
    end as margin_percent,
    case
        when revenue = 0 then 'no sales'
        when units_sold = 0 then 'no sales'
        when profit >= 10000 then 'high margin'
        when profit >= 5000 then 'medium margin'
        when profit >= 0 then 'low margin'
        else 'loss making'
    end as margin_category
from product_metrics;

-- --------------------------------------------------3
CREATE VIEW vw_order_summary AS
SELECT
    o.order_id,
    o.cust_id,                  
    c.cust_name,
    o.order_date,
    o.order_status,
    pm.payment_method,
    pm.payment_status,
    oi.prod_id,
    COUNT(DISTINCT oi.item_id) AS total_items,
    SUM(oi.quantity) AS total_units,
    COALESCE(ROUND(SUM(oi.quantity * oi.selling_price), 2), 0) AS revenue
FROM orders o
LEFT JOIN customers c ON o.cust_id = c.cust_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN payments pm ON o.order_id = pm.order_id
WHERE o.order_status IN ('delivered', 'shipped', 'pending', 'cancelled', 'returned')
GROUP BY o.order_id, o.cust_id, c.cust_name, o.order_date, o.order_status,
         pm.payment_method, pm.payment_status, oi.prod_id;

-- -----------------------------------------------4
create view vw_sales_summary as
with monthly_metrics as (
    select
        date_format(o.order_date, '%Y-%m-01') as month_date,
        date_format(o.order_date, '%M %Y') as month_name,
        count(distinct o.order_id) as total_orders,
        count(distinct c.cust_id) as total_customers,
        coalesce(round(sum(oi.quantity), 0), 0) as total_units_sold,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as cost,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as profit
    from orders o
    left join customers c on o.cust_id = c.cust_id
    left join order_items oi on o.order_id = oi.order_id
    left join products p on oi.prod_id = p.prod_id
    where o.order_status in ('delivered', 'shipped')
    group by date_format(o.order_date, '%Y-%m-01'), date_format(o.order_date, '%M %Y')
)
select
    month_date,
    month_name,
    total_orders,
    total_customers,
    total_units_sold,
    revenue,
    cost,
    profit,
    round(100.0 * profit / nullif(revenue, 0), 2) as profit_margin_percent,
    round(revenue / nullif(total_orders, 0), 2) as avg_order_value,
    round(revenue / nullif(total_customers, 0), 2) as revenue_per_customer,
    round(100.0 * (revenue - lag(revenue) over(order by month_date)) / nullif(lag(revenue) over(order by month_date), 0), 2) as revenue_growth_percent
from monthly_metrics;

-- -----------------------------------------------------------5
create view vw_inventory_summary as
with inventory_metrics as (
    select
        p.prod_id,
        p.prod_name,
        p.category,
        p.stock as current_stock,
        round(p.price * p.stock, 2) as inventory_value,
        coalesce(sum(oi.quantity), 0) as total_units_sold,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as total_revenue
    from orders o
	join order_items oi on o.order_id = oi.order_id
	join products p on oi.prod_id = p.prod_id
		WHERE o.order_status in ('delivered', 'shipped')
    group by p.prod_id, p.prod_name, p.category, p.stock, p.price
)
select
    prod_id,
    prod_name,
    category,
    current_stock,
    inventory_value,
    total_units_sold,
    total_revenue,
    case
        when current_stock = 0 then 'out of stock'
        when current_stock <= 10 then 'critical'
        when current_stock <= 25 then 'low stock'
        when current_stock <= 50 then 'medium stock'
        else 'in stock'
    end as stock_status,
    case
        when current_stock = 0 and total_units_sold > 0 then 'reorder immediately'
        when current_stock <= 10 then 'reorder soon'
        when current_stock <= 25 and total_units_sold > 0 then 'monitor stock'
        when current_stock > 50 and total_units_sold = 0 then 'overstocked'
        else 'healthy'
    end as reorder_status
from inventory_metrics;

-------- -------------------------- 6
create view vw_customer_clv as
with customer_metrics as (
    select
        c.cust_id,
        c.cust_name,
        c.city,
        c.state,
        min(o.order_date) as first_purchase_date,
        max(o.order_date) as last_purchase_date,
        coalesce(datediff(max(o.order_date), min(o.order_date)), 0) as customer_lifetime_days,
        count(distinct o.order_id) as total_orders,
        coalesce(sum(oi.quantity), 0) as total_units_purchased,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as total_revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as total_cost,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as total_profit
    from customers c
    left join orders o on c.cust_id = o.cust_id
        and o.order_status in ('delivered', 'shipped')
    left join order_items oi on o.order_id = oi.order_id
    left join products p on oi.prod_id = p.prod_id
    group by c.cust_id, c.cust_name, c.city, c.state
),
clv_metrics as (
    select
        *,
        case
            when total_orders = 0 then 0
            else round(total_revenue / total_orders, 2)
        end as avg_order_value,
        case
            when total_orders = 0 or customer_lifetime_days = 0 then 0
            else round(total_orders / nullif(customer_lifetime_days / 30.0, 0), 2)
        end as purchase_frequency,
        case
            when total_orders <= 1 then 0
            else round(customer_lifetime_days / (total_orders - 1), 0)
        end as avg_days_between_purchases,
        case
            when total_revenue = 0 then 0
            else round(100.0 * total_profit / total_revenue, 2)
        end as profit_margin_percent
    from customer_metrics
)
select
    cust_id,
    cust_name,
    city,
    state,
    first_purchase_date,
    last_purchase_date,
    customer_lifetime_days,
    total_orders,
    total_units_purchased,
    total_revenue,
    total_cost,
    total_profit,
    avg_order_value,
    purchase_frequency,
    avg_days_between_purchases,
    round(
        avg_order_value * purchase_frequency * (customer_lifetime_days / 365.0),
    2) as customer_lifetime_value,
    profit_margin_percent,
    case
        when total_orders = 0 then 'no orders'
        when total_revenue >= 500000 then 'vip'
        when total_revenue >= 200000 then 'gold'
        when total_revenue >= 100000 then 'silver'
        else 'bronze'
    end as customer_segment
from clv_metrics;

-- --------------------------------------------------------7
create view vw_campaign_performance as
with campaign_metrics as (
    select
        mc.campaign_id,
        mc.campaign_name,
        mc.campaign_type,
        mc.start_date,
        mc.end_date,
        mc.budget,
        count(distinct cc.cust_id) as customers_reached,
        count(distinct case when cc.campaign_status = 'opened' then cc.cust_id end) as opened,
        count(distinct case when cc.campaign_status = 'clicked' then cc.cust_id end) as clicked,
        count(distinct case when cc.campaign_status = 'purchased' then cc.cust_id end) as purchased
    from marketing_campaigns mc
    left join customer_campaigns cc on mc.campaign_id = cc.campaign_id
    group by mc.campaign_id, mc.campaign_name, mc.campaign_type, mc.start_date, mc.end_date, mc.budget
),
campaign_revenue as (
    select
        cc.campaign_id,
        count(distinct o.order_id) as total_orders,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as cost,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as profit,
        count(distinct case when o2.order_id is not null then c.cust_id end) as repeat_buyers
    from customer_campaigns cc
    left join customers c on cc.cust_id = c.cust_id
    left join marketing_campaigns mc on cc.campaign_id = mc.campaign_id  
    left join orders o on c.cust_id = o.cust_id
        and o.order_status in ('delivered', 'shipped')
        and o.order_date between mc.start_date and mc.end_date       
    left join order_items oi on o.order_id = oi.order_id
    left join products p on oi.prod_id = p.prod_id
    left join orders o2 on c.cust_id = o2.cust_id
        and o2.order_status in ('delivered', 'shipped')
        and o2.order_date > o.order_date
    group by cc.campaign_id
)
select
    cm.campaign_id,
    cm.campaign_name,
    cm.campaign_type,
    cm.start_date,
    cm.end_date,
    cm.budget,
    cm.customers_reached,
    cm.opened,
    cm.clicked,
    cm.purchased,
    round(100.0 * cm.opened / nullif(cm.customers_reached, 0), 2) as response_rate,
    round(100.0 * cm.clicked / nullif(cm.opened, 0), 2) as ctr,
    round(100.0 * cm.purchased / nullif(cm.clicked, 0), 2) as conversion_rate,
    cr.revenue,
    cr.profit,
    round(100.0 * cr.profit / nullif(cm.budget, 0), 2) as roi_percent,
    round(cm.budget / nullif(cm.purchased, 0), 2) as cpa,
    cr.repeat_buyers,
    round(100.0 * cr.repeat_buyers / nullif(cm.purchased, 0), 2) as repeat_rate,
    round(
        (cr.profit / nullif(cm.budget, 0)) * 10 +
        (cm.purchased / nullif(cm.customers_reached, 0)) * 5,
    2) as campaign_score,
    case
        when cm.customers_reached = 0 then 'no data'
        when cr.profit / nullif(cm.budget, 0) >= 2 then 'excellent'
        when cr.profit / nullif(cm.budget, 0) >= 1 then 'good'
        when cr.profit / nullif(cm.budget, 0) >= 0.5 then 'average'
        when cr.profit / nullif(cm.budget, 0) >= 0 then 'poor'
        else 'loss making'
    end as performance_category
from campaign_metrics cm
left join campaign_revenue cr on cm.campaign_id = cr.campaign_id;

-- ----------------------------------------------------------8
create view vw_product_performance as
with product_metrics as (
    select
        p.prod_id,
        p.prod_name,
        p.category,
        p.price as current_price,
        p.stock as current_stock,
        coalesce(sum(oi.quantity), 0) as units_sold,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as cost,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as profit
    from products p
    left join order_items oi on p.prod_id = oi.prod_id
    left join orders o on oi.order_id = o.order_id
        and o.order_status in ('delivered', 'shipped')
    group by p.prod_id, p.prod_name, p.category, p.price, p.stock
)
select
    prod_id,
    prod_name,
    category,
    current_price,
    current_stock,
    round(current_price * current_stock, 2) as inventory_value,
    units_sold,
    revenue,
    cost,
    profit,
    round(100.0 * profit / nullif(revenue, 0), 2) as profit_margin,
    case
        when units_sold = 0 then 'no sales'
        when profit >= 100000 then 'star product'
        when profit >= 50000 then 'good product'
        when profit >= 0 then 'average product'
        else 'loss making'
    end as product_rating,
    case
        when units_sold = 0 then 'no sales'
        when profit / nullif(revenue, 0) >= 0.30 then 'high performance'
        when profit / nullif(revenue, 0) >= 0.15 then 'medium performance'
        else 'low performance'
    end as performance_category
from product_metrics
order by profit desc;

-- ------------------------------------------------------9
create view vw_return_summary as
with return_metrics as (
    select
        r.return_id,
        r.order_id as return_order_id,
        r.prod_id,
        r.quantity as quantity_returned,
        r.reason as return_reason,
        r.return_date,
        c.cust_id,
        c.cust_name as customer,
        p.prod_name as product,
        p.category,
        o.order_date,
        datediff(r.return_date, o.order_date) as days_after_purchase,
        oi.selling_price as price_at_purchase,
        round(r.quantity * oi.selling_price, 2) as revenue_lost,
        round(r.quantity * oi.selling_price, 2) as refund_amount
    from returns r
    left join orders o on r.order_id = o.order_id
    left join customers c on o.cust_id = c.cust_id
    left join products p on r.prod_id = p.prod_id
    left join order_items oi on o.order_id = oi.order_id and r.prod_id = oi.prod_id
),
total_orders as (
    select
        oi.prod_id,
        count(distinct oi.order_id) as total_orders,
        sum(oi.quantity) as total_units_sold
    from order_items oi
    join orders o on oi.order_id = o.order_id
    where o.order_status in ('delivered', 'shipped')
    group by oi.prod_id
),
return_rate as (
    select
        r.prod_id,
        count(distinct r.return_id) as return_count,
        sum(r.quantity) as returned_units
    from returns r
    group by r.prod_id
)
select
    rm.return_id,
    rm.return_order_id as order_id,
    rm.product,
    rm.customer,
    rm.category,
    rm.return_date,
    rm.quantity_returned,
    rm.revenue_lost,
    rm.return_reason,
    rm.days_after_purchase,
    rm.refund_amount,
    coalesce(tr.total_orders, 0) as total_orders,
    coalesce(tr.total_units_sold, 0) as total_units_sold,
    coalesce(rr.return_count, 0) as total_returns,
    coalesce(rr.returned_units, 0) as total_returned_units,
    round(100.0 * coalesce(rr.returned_units, 0) / nullif(coalesce(tr.total_units_sold, 0), 0), 2) as returned_percent,
    case
        when coalesce(rr.returned_units, 0) = 0 then 'no returns'
        when coalesce(rr.returned_units, 0) * 1.0 / nullif(coalesce(tr.total_units_sold, 0), 0) >= 0.20 then 'high return'
        when coalesce(rr.returned_units, 0) * 1.0 / nullif(coalesce(tr.total_units_sold, 0), 0) >= 0.10 then 'medium return'
        else 'low return'
    end as return_category,
    case
        when rm.days_after_purchase <= 7 then 'immediate'
        when rm.days_after_purchase <= 30 then 'early'
        when rm.days_after_purchase <= 60 then 'standard'
        else 'late'
    end as return_timing
from return_metrics rm
left join total_orders tr on rm.prod_id = tr.prod_id
left join return_rate rr on rm.prod_id = rr.prod_id
order by rm.return_date desc;

-- --------------------------------------------------------10
create view vw_payment_summary as
with payment_metrics as (
    select
        pm.payment_method,
        count(distinct pm.payment_id) as total_transactions,
        count(distinct case when pm.payment_status = 'success' then pm.payment_id end) as successful_payments,
        count(distinct case when pm.payment_status = 'failed' then pm.payment_id end) as failed_payments,
        count(distinct case when pm.payment_status = 'refunded' then pm.payment_id end) as refunded_payments,
        count(distinct case when pm.payment_status = 'pending' then pm.payment_id end) as pending_payments,
        coalesce(round(sum(case when pm.payment_status = 'success' then pm.amount else 0 end), 2), 0) as revenue,
        coalesce(round(sum(case when pm.payment_status = 'refunded' then pm.amount else 0 end), 2), 0) as refund_amount,
        round(avg(pm.amount), 2) as avg_transaction_value,
        round(min(pm.amount), 2) as lowest_transaction,
        round(max(pm.amount), 2) as highest_transaction
    from payments pm
    left join orders o on pm.order_id = o.order_id
    where o.order_status in ('delivered', 'shipped', 'pending', 'cancelled', 'returned') or o.order_status is null
    group by pm.payment_method
),
payment_rate as (
    select
        payment_method,
        total_transactions,
        successful_payments,
        refunded_payments,
        round(100.0 * successful_payments / nullif(total_transactions, 0), 2) as success_rate,
        round(100.0 * refunded_payments / nullif(total_transactions, 0), 2) as refund_rate,
        round(100.0 * failed_payments / nullif(total_transactions, 0), 2) as failure_rate
    from payment_metrics
)
select
    pm.payment_method,
    pm.total_transactions,
    pm.successful_payments,
    pm.failed_payments,
    pm.refunded_payments,
    pm.pending_payments,
    pm.revenue,
    pm.refund_amount,
    pr.success_rate,
    pr.refund_rate,
    pr.failure_rate,
    pm.avg_transaction_value,
    pm.lowest_transaction,
    pm.highest_transaction,
    case
        when pm.total_transactions = 0 then 'no data'
        when pr.success_rate >= 95 then 'excellent'
        when pr.success_rate >= 85 then 'good'
        when pr.success_rate >= 70 then 'average'
        else 'poor'
    end as payment_performance
from payment_metrics pm
left join payment_rate pr on pm.payment_method = pr.payment_method
order by pr.success_rate desc;

-- -------------------------------------------------- 11
create view vw_dashboard_sales as
with monthly_metrics as (
    select
        date_format(o.order_date, '%Y-%m-01') as month_date,
        date_format(o.order_date, '%M %Y') as month_name,
        count(distinct o.order_id) as total_orders,
        count(distinct case when o.order_status = 'delivered' then o.order_id end) as delivered_orders,
        count(distinct case when o.order_status = 'cancelled' then o.order_id end) as cancelled_orders,
        count(distinct c.cust_id) as total_customers,
        coalesce(sum(oi.quantity), 0) as units_sold,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as cost,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as profit,
        coalesce(round(avg(oi.quantity * oi.selling_price), 2), 0) as avg_order_value
    from orders o
    left join customers c on o.cust_id = c.cust_id
    left join order_items oi on o.order_id = oi.order_id
    left join products p on oi.prod_id = p.prod_id
    where o.order_status in ('delivered', 'shipped', 'pending', 'cancelled', 'returned')
    group by date_format(o.order_date, '%Y-%m-01'), date_format(o.order_date, '%M %Y')
),
return_metrics as (
    select
        date_format(r.return_date, '%Y-%m-01') as return_month,
        count(distinct r.return_id) as total_returns
    from returns r
    group by date_format(r.return_date, '%Y-%m-01')
)
select
    mm.month_date,
    mm.month_name,
    mm.total_orders,
    mm.delivered_orders,
    mm.cancelled_orders,
    mm.total_customers,
    mm.units_sold,
    mm.revenue,
    mm.cost,
    mm.profit,
    round(100.0 * mm.profit / nullif(mm.revenue, 0), 2) as profit_margin_percent,
    mm.avg_order_value,
    round(100.0 * (mm.revenue - lag(mm.revenue) over(order by mm.month_date)) / nullif(lag(mm.revenue) over(order by mm.month_date), 0), 2) as revenue_growth_percent,
    round(100.0 * (mm.total_orders - lag(mm.total_orders) over(order by mm.month_date)) / nullif(lag(mm.total_orders) over(order by mm.month_date), 0), 2) as order_growth_percent,
    coalesce(rm.total_returns, 0) as total_returns,
    round(100.0 * coalesce(rm.total_returns, 0) / nullif(mm.delivered_orders, 0), 2) as return_percent
from monthly_metrics mm
left join return_metrics rm on mm.month_date = rm.return_month
order by mm.month_date;

-- --------------------------------------------------------12
create view vw_dashboard_customers as
with customer_metrics as (
    select
        c.cust_id,
        c.cust_name,
        c.city,
        c.state,
        c.signup_date,
        count(distinct o.order_id) as total_orders,
        coalesce(sum(oi.quantity), 0) as total_units_purchased,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as cost,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as profit,
        min(o.order_date) as first_purchase_date,
        max(o.order_date) as last_purchase_date,
        datediff(curdate(), max(o.order_date)) as days_since_last_purchase
    from customers c
    left join orders o on c.cust_id = o.cust_id
        and o.order_status in ('delivered', 'shipped')
    left join order_items oi on o.order_id = oi.order_id
    left join products p on oi.prod_id = p.prod_id
    group by c.cust_id, c.cust_name, c.city, c.state, c.signup_date
),
clv_metrics as (
    select
        *,
        case
            when total_orders = 0 then 0
            else round(revenue / total_orders, 2)
        end as avg_order_value,
        case
            when total_orders = 0 then 0
            else round(datediff(last_purchase_date, first_purchase_date) / 30.0, 2)
        end as customer_lifespan_months,
        case
            when total_orders <= 1 or total_orders = 0 then 0
            else round(datediff(last_purchase_date, first_purchase_date) / (total_orders - 1), 0)
        end as avg_days_between_purchases,
        round(
            (case when total_orders = 0 then 0 else round(revenue / total_orders, 2) end) *
            (case when total_orders = 0 then 0 else round(total_orders / nullif(datediff(last_purchase_date, first_purchase_date) / 30.0, 0), 2) end) *
            (case when total_orders = 0 then 0 else round(datediff(last_purchase_date, first_purchase_date) / 365.0, 2) end),
        2) as clv
    from customer_metrics
)
select
    cust_id,
    cust_name,
    city,
    state,
    total_orders,
    revenue,
    profit,
    clv as customer_lifetime_value,
    avg_order_value,
    last_purchase_date,
    days_since_last_purchase,
    case
        when total_orders = 0 then 'no orders'
        when clv >= 1000000 then 'vip'
        when clv >= 500000 then 'gold'
        when clv >= 200000 then 'silver'
        when clv >= 50000 then 'bronze'
        else 'starter'
    end as customer_segment,
    case
        when total_orders = 0 then 'no orders'
        when total_orders >= 10 then 'high frequency'
        when total_orders >= 5 then 'medium frequency'
        when total_orders >= 2 then 'low frequency'
        else 'new'
    end as purchase_frequency,
    case
        when total_orders = 0 then 'no orders'
        when days_since_last_purchase <= 30 then 'active'
        when days_since_last_purchase <= 60 then 'engaged'
        when days_since_last_purchase <= 90 then 'at risk'
        else 'dormant'
    end as customer_health
from clv_metrics
order by clv desc;

-- ---------------------------------------------------13
create view vw_dashboard_products as
with product_metrics as (
    select
        p.prod_id,
        p.prod_name,
        p.category,
        p.price,
        p.stock as current_stock,
        round(p.price * p.stock, 2) as inventory_value,
        coalesce(sum(oi.quantity), 0) as units_sold,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as cost,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as profit
    from products p
    left join order_items oi on p.prod_id = oi.prod_id
    left join orders o on oi.order_id = o.order_id
        and o.order_status in ('delivered', 'shipped')
    group by p.prod_id, p.prod_name, p.category, p.price, p.stock
),
return_metrics as (
    select
        r.prod_id,
        count(distinct r.return_id) as total_returns,
        coalesce(sum(r.quantity), 0) as returned_units
    from returns r
    group by r.prod_id
),
review_metrics as (
    select
        rv.prod_id,
        round(avg(rv.rating), 2) as avg_rating,
        count(distinct rv.review_id) as review_count
    from reviews rv
    group by rv.prod_id
)
select
    pm.prod_id,
    pm.prod_name,
    pm.category,
    pm.units_sold,
    pm.revenue,
    pm.profit,
    round(100.0 * pm.profit / nullif(pm.revenue, 0), 2) as margin_percent,
    pm.current_stock,
    pm.inventory_value,
    coalesce(rm.total_returns, 0) as total_returns,
    coalesce(rm.returned_units, 0) as returned_units,
    round(100.0 * coalesce(rm.returned_units, 0) / nullif(pm.units_sold, 0), 2) as return_percent,
    coalesce(rvm.avg_rating, 0) as avg_rating,
    coalesce(rvm.review_count, 0) as review_count,
    case
        when pm.units_sold = 0 then 'no sales'
        when pm.profit >= 100000 then 'star product'
        when pm.profit >= 50000 then 'good product'
        when pm.profit >= 0 then 'average product'
        else 'loss making'
    end as product_status,
    case
        when pm.units_sold = 0 then 'no sales'
        when pm.current_stock <= 10 and pm.units_sold > 0 then 'low stock'
        when pm.current_stock <= 25 and pm.units_sold > 0 then 'stock alert'
        when pm.current_stock > 50 and pm.units_sold = 0 then 'overstocked'
        else 'healthy'
    end as inventory_status,
    case
        when pm.units_sold = 0 then 'no sales'
        when coalesce(rm.returned_units, 0) * 1.0 / nullif(pm.units_sold, 0) >= 0.20 then 'high return'
        when coalesce(rm.returned_units, 0) * 1.0 / nullif(pm.units_sold, 0) >= 0.10 then 'medium return'
        else 'low return'
    end as return_category,
    case
        when coalesce(rvm.avg_rating, 0) >= 4.5 then 'top rated'
        when coalesce(rvm.avg_rating, 0) >= 4.0 then 'good'
        when coalesce(rvm.avg_rating, 0) >= 3.0 then 'average'
        when coalesce(rvm.avg_rating, 0) > 0 then 'poor'
        else 'no reviews'
    end as rating_status,
    rank() over(order by pm.revenue desc) as revenue_rank,
    rank() over(order by pm.profit desc) as profit_rank,
    rank() over(order by pm.units_sold desc) as sales_rank
from product_metrics pm
left join return_metrics rm on pm.prod_id = rm.prod_id
left join review_metrics rvm on pm.prod_id = rvm.prod_id
order by pm.revenue desc;

-- ---------------------------------------------------14
create view vw_dashboard_marketing as
with campaign_metrics as (
    select
        mc.campaign_id,
        mc.campaign_name,
        mc.campaign_type,
        mc.budget,
        mc.start_date,
        mc.end_date,
        count(distinct cc.cust_id) as customers_reached,
        count(distinct case when cc.campaign_status = 'opened' then cc.cust_id end) as opened,
        count(distinct case when cc.campaign_status = 'clicked' then cc.cust_id end) as clicked,
        count(distinct case when cc.campaign_status = 'purchased' then cc.cust_id end) as purchased
    from marketing_campaigns mc
    left join customer_campaigns cc on mc.campaign_id = cc.campaign_id
    group by mc.campaign_id, mc.campaign_name, mc.campaign_type, mc.budget, mc.start_date, mc.end_date
),
campaign_revenue as (
    select
        cc.campaign_id,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as cost,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as profit,
        count(distinct case when o2.order_id is not null then c.cust_id end) as repeat_buyers
    from customer_campaigns cc
    left join customers c on cc.cust_id = c.cust_id
    left join marketing_campaigns mc on cc.campaign_id = mc.campaign_id
    left join orders o on c.cust_id = o.cust_id
        and o.order_status in ('delivered', 'shipped')
        and o.order_date between mc.start_date and mc.end_date
    left join order_items oi on o.order_id = oi.order_id
    left join products p on oi.prod_id = p.prod_id
    left join orders o2 on c.cust_id = o2.cust_id
        and o2.order_status in ('delivered', 'shipped')
        and o2.order_date > o.order_date
    group by cc.campaign_id
)
select
    cm.campaign_id,
    cm.campaign_name,
    cm.campaign_type,
    cm.budget,
    cm.start_date,
    cm.end_date,
    cm.customers_reached,
    cm.opened,
    cm.clicked,
    cm.purchased as conversions,
    round(100.0 * cm.opened / nullif(cm.customers_reached, 0), 2) as response_rate,
    round(100.0 * cm.clicked / nullif(cm.opened, 0), 2) as ctr,
    round(100.0 * cm.purchased / nullif(cm.clicked, 0), 2) as conversion_rate,
    cr.revenue,
    cr.profit,
    round(100.0 * cr.profit / nullif(cm.budget, 0), 2) as roi,
    round(cm.budget / nullif(cm.purchased, 0), 2) as cpa,
    cr.repeat_buyers,
    round(100.0 * cr.repeat_buyers / nullif(cm.purchased, 0), 2) as repeat_rate,
    round(
        (cr.profit / nullif(cm.budget, 0)) * 5 +
        (cm.purchased / nullif(cm.customers_reached, 0)) * 3 +
        (cr.repeat_buyers / nullif(cm.purchased, 0)) * 2,
    2) as campaign_score,
    case
        when cm.customers_reached = 0 then 'no data'
        when cr.profit / nullif(cm.budget, 0) >= 2 then 'star campaign'
        when cr.profit / nullif(cm.budget, 0) >= 1 then 'good campaign'
        when cr.profit / nullif(cm.budget, 0) >= 0.5 then 'average campaign'
        when cr.profit / nullif(cm.budget, 0) >= 0 then 'poor campaign'
        else 'loss making'
    end as campaign_rating
from campaign_metrics cm
left join campaign_revenue cr on cm.campaign_id = cr.campaign_id
order by cr.profit desc;

-- ----------------------------------------------------15
create view vw_dashboard_executive as
with revenue_metrics as (
    select
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as total_revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as total_cost,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as gross_profit,
        count(distinct o.order_id) as total_orders,
        count(distinct c.cust_id) as total_customers
    from orders o
    left join customers c on o.cust_id = c.cust_id
    left join order_items oi on o.order_id = oi.order_id
    left join products p on oi.prod_id = p.prod_id
    where o.order_status in ('delivered', 'shipped')
),
return_metrics as (
    select
        count(distinct r.return_id) as total_returns,
        coalesce(round(sum(r.quantity * oi.selling_price), 2), 0) as return_revenue
    from returns r
    left join order_items oi on r.order_id = oi.order_id and r.prod_id = oi.prod_id
),
refund_metrics as (
    select
        count(distinct pm.payment_id) as total_refunds,
        coalesce(round(sum(pm.amount), 2), 0) as refund_amount
    from payments pm
    where pm.payment_status = 'refunded'
),
review_metrics as (
    select
        round(avg(rating), 2) as avg_rating
    from reviews
),
top_product as (
    select
        p.prod_name
    from products p
    left join order_items oi on p.prod_id = oi.prod_id
    left join orders o on oi.order_id = o.order_id
        and o.order_status in ('delivered', 'shipped')
    group by p.prod_name
    order by sum(oi.quantity * oi.selling_price) desc
    limit 1
),
top_category as (
    select
        p.category
    from products p
    left join order_items oi on p.prod_id = oi.prod_id
    left join orders o on oi.order_id = o.order_id
        and o.order_status in ('delivered', 'shipped')
    group by p.category
    order by sum(oi.quantity * oi.selling_price) desc
    limit 1
),
top_city as (
    select
        c.city
    from customers c
    left join orders o on c.cust_id = o.cust_id
        and o.order_status in ('delivered', 'shipped')
    left join order_items oi on o.order_id = oi.order_id
    group by c.city
    order by sum(oi.quantity * oi.selling_price) desc
    limit 1
),
top_campaign as (
    select
        mc.campaign_name
    from marketing_campaigns mc
    left join customer_campaigns cc on mc.campaign_id = cc.campaign_id
    left join customers c on cc.cust_id = c.cust_id
    left join orders o on c.cust_id = o.cust_id
        and o.order_status in ('delivered', 'shipped')
    left join order_items oi on o.order_id = oi.order_id
    group by mc.campaign_name
    order by sum(oi.quantity * oi.selling_price) desc
    limit 1
),
top_payment as (
    select
        pm.payment_method
    from payments pm
    left join orders o on pm.order_id = o.order_id
    where pm.payment_status = 'success'
    group by pm.payment_method
    order by sum(pm.amount) desc
    limit 1
),
clv_metrics as (
    select
        round(sum(oi.quantity * oi.selling_price) / count(distinct c.cust_id), 2) as avg_clv
    from orders o
    left join customers c on o.cust_id = c.cust_id
    left join order_items oi on o.order_id = oi.order_id
    where o.order_status in ('delivered', 'shipped')
)
select
    rm.total_revenue,
    round(rm.total_revenue - coalesce(rt.return_revenue, 0) - coalesce(rf.refund_amount, 0), 2) as net_revenue,
    rm.gross_profit,
    round(rm.gross_profit - coalesce(rt.return_revenue, 0) - coalesce(rf.refund_amount, 0), 2) as net_profit,
    rm.total_orders,
    rm.total_customers,
    round(rm.total_revenue / nullif(rm.total_orders, 0), 2) as avg_order_value,
    clv.avg_clv as customer_lifetime_value,
    round(100.0 * rt.total_returns / nullif(rm.total_orders, 0), 2) as return_rate,
    round(100.0 * rf.total_refunds / nullif(rm.total_orders, 0), 2) as refund_rate,
    rv.avg_rating as avg_rating,
    round(100.0 * rm.gross_profit / nullif(rm.total_revenue, 0), 2) as profit_margin,
    tp.prod_name as top_product,
    tc.category as top_category,
    tcity.city as top_city,
    tcam.campaign_name as top_campaign,
    tpay.payment_method as best_payment_method
from revenue_metrics rm
cross join return_metrics rt
cross join refund_metrics rf
cross join review_metrics rv
cross join clv_metrics clv
cross join top_product tp
cross join top_category tc
cross join top_city tcity
cross join top_campaign tcam
cross join top_payment tpay;

------------------------------------------------- 16
create view vw_monthly_customer_revenue as
with monthly_customer as (
    select
        c.cust_id,
        c.cust_name,
        date_format(o.order_date, '%Y-%m-01') as month_date,
        date_format(o.order_date, '%M %Y') as month_name,
        count(distinct o.order_id) as orders,
        coalesce(sum(oi.quantity), 0) as units_sold,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as cost,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as profit
    from customers c
    left join orders o on c.cust_id = o.cust_id
        and o.order_status in ('delivered', 'shipped')
    left join order_items oi on o.order_id = oi.order_id
    left join products p on oi.prod_id = p.prod_id
    group by c.cust_id, c.cust_name, date_format(o.order_date, '%Y-%m-01'), date_format(o.order_date, '%M %Y')
)
select
    month_date,
    month_name,
    cust_id,
    cust_name,
    orders,
    units_sold,
    revenue,
    cost,
    profit,
    case
        when orders = 0 then 0
        else round(revenue / orders, 2)
    end as avg_order_value,
    round(100.0 * profit / nullif(revenue, 0), 2) as profit_margin,
    round(100.0 * (revenue - lag(revenue) over(partition by cust_id order by month_date)) / 
          nullif(lag(revenue) over(partition by cust_id order by month_date), 0), 2) as revenue_growth,
    row_number() over(partition by month_date order by revenue desc) as month_rank
from monthly_customer
order by month_date, revenue desc;

-- ----------------------------------------------17
create view vw_monthly_product_revenue as
with monthly_product as (
    select
        date_format(o.order_date, '%Y-%m-01') as month_date,
        date_format(o.order_date, '%M %Y') as month_name,
        p.prod_id,
        p.prod_name,
        p.category,
        coalesce(sum(oi.quantity), 0) as units_sold,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as cost,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as profit
    from products p
    left join order_items oi on p.prod_id = oi.prod_id
    left join orders o on oi.order_id = o.order_id
        and o.order_status in ('delivered', 'shipped')
    group by date_format(o.order_date, '%Y-%m-01'), date_format(o.order_date, '%M %Y'), p.prod_id, p.prod_name, p.category
)
select
    month_date,
    month_name,
    prod_id,
    prod_name,
    category,
    units_sold,
    revenue,
    cost,
    profit,
    case
        when units_sold = 0 then 0
        else round(revenue / units_sold, 2)
    end as avg_price,
    case
        when revenue = 0 then 0
        else round(100.0 * profit / revenue, 2)
    end as profit_margin,
    round(100.0 * (revenue - lag(revenue) over(partition by prod_id order by month_date)) / 
          nullif(lag(revenue) over(partition by prod_id order by month_date), 0), 2) as revenue_growth,
    row_number() over(partition by month_date order by revenue desc) as month_rank,
    rank() over(partition by category, month_date order by revenue desc) as category_rank
from monthly_product
where prod_id is not null
order by month_date, revenue desc;

-- ---------------------------------------------------18
create view vw_customer_purchase_frequency as
with customer_metrics as (
    select
        c.cust_id,
        c.cust_name,
        c.city,
        c.state,
        count(distinct o.order_id) as total_orders,
        coalesce(sum(oi.quantity), 0) as total_units_purchased,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as total_revenue,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as total_profit,
        min(o.order_date) as first_purchase_date,
        max(o.order_date) as last_purchase_date,
        datediff(curdate(), max(o.order_date)) as days_since_last_purchase
    from customers c
    left join orders o on c.cust_id = o.cust_id
        and o.order_status in ('delivered', 'shipped')
    left join order_items oi on o.order_id = oi.order_id
    left join products p on oi.prod_id = p.prod_id
    group by c.cust_id, c.cust_name, c.city, c.state
),
frequency_metrics as (
    select
        *,
        case
            when total_orders <= 1 then 0
            else round(datediff(last_purchase_date, first_purchase_date) / (total_orders - 1), 0)
        end as days_between_orders,
        case
            when total_orders = 0 then 0
            else round(total_orders / nullif(datediff(last_purchase_date, first_purchase_date) / 30.0, 0), 2)
        end as orders_per_month,
        case
            when total_orders = 0 then 0
            else round(total_units_purchased / total_orders, 2)
        end as avg_basket_size,
        case
            when total_orders = 0 then 0
            else round(total_revenue / total_orders, 2)
        end as avg_order_value,
        case
            when total_revenue = 0 or total_orders = 0 then 0
            else round(total_revenue / total_orders * (total_orders / nullif(datediff(last_purchase_date, first_purchase_date) / 30.0, 0)) * (datediff(last_purchase_date, first_purchase_date) / 365.0), 2)
        end as customer_lifetime_value
    from customer_metrics
)
select
    cust_id,
    cust_name,
    city,
    state,
    total_orders,
    days_between_orders,
    orders_per_month,
    avg_basket_size,
    avg_order_value,
    total_revenue,
    total_profit,
    customer_lifetime_value,
    last_purchase_date,
    days_since_last_purchase,
    case
        when total_orders = 0 then 'no orders'
        when days_between_orders <= 15 then 'very frequent'
        when days_between_orders <= 30 then 'frequent'
        when days_between_orders <= 60 then 'occasional'
        when days_between_orders > 0 then 'rare'
        else 'inactive'
    end as frequency_category,
    case
        when total_orders = 0 then 'no orders'
        when total_orders >= 10 then 'high volume'
        when total_orders >= 5 then 'medium volume'
        when total_orders >= 2 then 'low volume'
        else 'new'
    end as volume_category
from frequency_metrics
order by total_orders desc;

-- --------------------------------------------19
create view vw_top_product_by_month as
with monthly_product as (
    select
        date_format(o.order_date, '%Y-%m-01') as month_date,
        date_format(o.order_date, '%M %Y') as month_name,
        p.prod_id,
        p.prod_name,
        p.category,
        coalesce(sum(oi.quantity), 0) as units_sold,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as revenue,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as profit,
        round(100.0 * (sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price)) / 
              nullif(sum(oi.quantity * oi.selling_price), 0), 2) as profit_margin
    from products p
    left join order_items oi on p.prod_id = oi.prod_id
    left join orders o on oi.order_id = o.order_id
        and o.order_status in ('delivered', 'shipped')
    group by date_format(o.order_date, '%Y-%m-01'), date_format(o.order_date, '%M %Y'), p.prod_id, p.prod_name, p.category
),
ranked_products as (
    select
        month_date,
        month_name,
        prod_id,
        prod_name,
        category,
        units_sold,
        revenue,
        profit,
        profit_margin,
        rank() over(partition by month_date order by revenue desc) as revenue_rank,
        rank() over(partition by month_date order by units_sold desc) as sales_rank,
        dense_rank() over(partition by month_date order by revenue desc) as dense_revenue_rank
    from monthly_product
    where revenue > 0
)
select
    month_date,
    month_name,
    prod_id,
    prod_name,
    category,
    units_sold,
    revenue,
    profit,
    profit_margin,
    revenue_rank,
    sales_rank,
    dense_revenue_rank,
    case
        when revenue_rank = 1 then 'top product'
        when revenue_rank <= 3 then 'top 3'
        when revenue_rank <= 5 then 'top 5'
        else 'others'
    end as product_tier
from ranked_products
where revenue_rank = 1
order by month_date desc;

---------------------------------------------20
create view vw_campaign_revenue_by_month as
with campaign_monthly as (
    select
        date_format(o.order_date, '%Y-%m-01') as month_date,
        date_format(o.order_date, '%M %Y') as month_name,
        mc.campaign_id,
        mc.campaign_name,
        mc.campaign_type,
        mc.budget,
        count(distinct o.order_id) as orders,
        count(distinct c.cust_id) as customers,
        coalesce(sum(oi.quantity), 0) as units_sold,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as cost,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as profit,
        count(distinct case when o2.order_id is not null then c.cust_id end) as repeat_buyers
    from marketing_campaigns mc
    left join customer_campaigns cc on mc.campaign_id = cc.campaign_id
    left join customers c on cc.cust_id = c.cust_id
    left join orders o on c.cust_id = o.cust_id
        and o.order_status in ('delivered', 'shipped')
        and o.order_date between mc.start_date and mc.end_date
    left join order_items oi on o.order_id = oi.order_id
    left join products p on oi.prod_id = p.prod_id
    left join orders o2 on c.cust_id = o2.cust_id
        and o2.order_status in ('delivered', 'shipped')
        and o2.order_date > o.order_date
    group by date_format(o.order_date, '%Y-%m-01'), date_format(o.order_date, '%M %Y'), mc.campaign_id, mc.campaign_name, mc.campaign_type, mc.budget
),
monthly_roi as (
    select
        *,
        round(100.0 * profit / nullif(budget, 0), 2) as roi_percent,
        round(budget / nullif(customers, 0), 2) as cpa,
        round(100.0 * repeat_buyers / nullif(customers, 0), 2) as repeat_rate,
        row_number() over(partition by month_date order by revenue desc) as campaign_rank
    from campaign_monthly
)
select
    month_date,
    month_name,
    campaign_id,
    campaign_name,
    campaign_type,
    budget,
    orders,
    customers,
    units_sold,
    revenue,
    cost,
    profit,
    roi_percent,
    cpa,
    repeat_buyers,
    repeat_rate,
    campaign_rank,
    case
        when revenue = 0 then 'no revenue'
        when roi_percent >= 200 then 'star campaign'
        when roi_percent >= 100 then 'high performing'
        when roi_percent >= 50 then 'good campaign'
        when roi_percent >= 0 then 'low performing'
        else 'loss making'
    end as campaign_status
from monthly_roi
where revenue > 0
order by month_date desc, revenue desc;

-- -----------------------------------------------------------21
create view vw_customer_segmentation as
with customer_metrics as (
    select
        c.cust_id,
        c.cust_name,
        c.city,
        c.state,
        c.signup_date,
        count(distinct o.order_id) as total_orders,
        coalesce(sum(oi.quantity), 0) as total_units,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as total_revenue,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as total_profit,
        min(o.order_date) as first_purchase,
        max(o.order_date) as last_purchase,
        datediff(curdate(), max(o.order_date)) as days_since_last_purchase,
        datediff(curdate(), c.signup_date) as customer_age_days
    from customers c
    left join orders o on c.cust_id = o.cust_id
        and o.order_status in ('delivered', 'shipped')
    left join order_items oi on o.order_id = oi.order_id
    left join products p on oi.prod_id = p.prod_id
    group by c.cust_id, c.cust_name, c.city, c.state, c.signup_date
),
frequency_metrics as (
    select
        *,
        case
            when total_orders <= 1 then 0
            else round(datediff(last_purchase, first_purchase) / (total_orders - 1), 0)
        end as days_between_orders,
        case
            when total_orders = 0 then 0
            else round(total_revenue / total_orders, 2)
        end as avg_order_value,
        case
            when total_orders = 0 then 0
            else round(total_revenue / nullif(datediff(last_purchase, first_purchase) / 30.0, 0), 2)
        end as orders_per_month
    from customer_metrics
)
select
    cust_id,
    cust_name,
    city,
    state,
    total_orders,
    total_revenue,
    total_profit,
    avg_order_value,
    days_between_orders,
    orders_per_month,
    last_purchase,
    days_since_last_purchase,
    customer_age_days,
    case
        when total_orders = 0 then 'inactive'
        when total_orders >= 10 and total_revenue >= 500000 then 'vip'
        when total_orders >= 5 and total_revenue >= 200000 then 'loyal'
        when total_orders >= 3 and total_revenue >= 100000 then 'high value'
        when total_orders >= 2 and total_revenue >= 50000 then 'potential loyalist'
        when total_orders = 1 and total_revenue >= 10000 then 'new customer'
        when total_orders = 1 then 'one-time buyer'
        when days_since_last_purchase >= 180 and total_orders >= 2 then 'lost'
        when days_since_last_purchase >= 90 and total_orders >= 2 then 'at risk'
        else 'regular'
    end as customer_segment,
    case
        when total_orders = 0 then 'no activity'
        when days_since_last_purchase <= 30 then 'active'
        when days_since_last_purchase <= 60 then 'engaged'
        when days_since_last_purchase <= 90 then 'warming'
        when days_since_last_purchase <= 180 then 'cooling'
        else 'cold'
    end as engagement_status,
    case
        when total_orders = 0 then 'no orders'
        when total_orders >= 10 then 'frequent'
        when total_orders >= 5 then 'regular'
        when total_orders >= 2 then 'occasional'
        else 'new'
    end as frequency_status,
    row_number() over(order by total_revenue desc) as revenue_rank,
    row_number() over(order by total_orders desc) as frequency_rank
from frequency_metrics
order by total_revenue desc;

-- -----------------------------------------------22
create view vw_rfm_analysis as
with customer_rfm_data as (
    select
        c.cust_id,
        c.cust_name,
        c.city,
        c.state,
        datediff(curdate(), coalesce(max(o.order_date), curdate())) as recency,
        count(distinct o.order_id) as frequency,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as monetary
    from customers c
    left join orders o on c.cust_id = o.cust_id
        and o.order_status in ('delivered', 'shipped')
    left join order_items oi on o.order_id = oi.order_id
    group by c.cust_id, c.cust_name, c.city, c.state
),
rfm_scores as (
    select
        cust_id,
        cust_name,
        city,
        state,
        recency,
        frequency,
        monetary,
        ntile(5) over(order by recency asc) as r_score,
        ntile(5) over(order by frequency desc) as f_score,
        ntile(5) over(order by monetary desc) as m_score,
        concat(
            ntile(5) over(order by recency asc),
            ntile(5) over(order by frequency desc),
            ntile(5) over(order by monetary desc)
        ) as rfm_score,
        ntile(5) over(order by recency asc) +
        ntile(5) over(order by frequency desc) +
        ntile(5) over(order by monetary desc) as rfm_total
    from customer_rfm_data
),
rfm_segments as (
    select
        *,
        case
            when r_score = 5 and f_score >= 4 and m_score >= 4 then 'champions'
            when r_score >= 4 and f_score >= 3 and m_score >= 3 then 'loyal customers'
            when r_score >= 3 and f_score >= 3 and m_score >= 3 then 'potential loyalists'
            when r_score >= 3 and f_score >= 2 and m_score >= 2 then 'need attention'
            when r_score <= 2 and (f_score >= 3 or m_score >= 3) then 'at risk'
            when r_score <= 2 and f_score <= 2 and m_score <= 2 then 'lost customers'
            when r_score >= 4 and f_score <= 2 then 'new customers'
            else 'other'
        end as rfm_segment,
        case
            when r_score = 5 and f_score = 5 and m_score = 5 then 'vip'
            when r_score >= 4 and f_score >= 4 then 'high value'
            when r_score >= 3 and f_score >= 3 then 'medium value'
            else 'low value'
        end as value_tier
    from rfm_scores
)
select
    cust_id,
    cust_name,
    city,
    state,
    recency as days_since_last_order,
    frequency as total_orders,
    monetary as total_revenue,
    r_score,
    f_score,
    m_score,
    rfm_score,
    rfm_total,
    rfm_segment,
    value_tier,
    case
        when r_score >= 4 then ' recent'
        when r_score >= 3 then ' moderate'
        else ' old'
    end as recency_label,
    case
        when f_score >= 4 then ' frequent'
        when f_score >= 3 then ' moderate'
        else ' rare'
    end as frequency_label,
    case
        when m_score >= 4 then ' high spender'
        when m_score >= 3 then ' moderate'
        else ' low spender'
    end as monetary_label
from rfm_segments
order by rfm_total desc, monetary desc;

--------------------------------------------------------23
create view vw_abc_product_classification as
with product_metrics as (
    select
        p.prod_id,
        p.prod_name,
        p.category,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as revenue,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as profit,
        coalesce(sum(oi.quantity), 0) as units_sold
    from products p
    left join order_items oi on p.prod_id = oi.prod_id
    left join orders o on oi.order_id = o.order_id
        and o.order_status in ('delivered', 'shipped')
    group by p.prod_id, p.prod_name, p.category
),
ranked_products as (
    select
        prod_id,
        prod_name,
        category,
        revenue,
        profit,
        units_sold,
        round(100.0 * profit / nullif(revenue, 0), 2) as margin_percent,
        sum(revenue) over() as total_revenue,
        sum(revenue) over(order by revenue desc) as running_revenue,
        round(100.0 * sum(revenue) over(order by revenue desc) / sum(revenue) over(), 2) as running_percent,
        round(100.0 * revenue / sum(revenue) over(), 2) as revenue_contribution,
        round(100.0 * profit / sum(profit) over(), 2) as profit_contribution,
        row_number() over(order by revenue desc) as product_rank
    from product_metrics
    where revenue > 0
)
select
    product_rank,
    prod_id,
    prod_name,
    category,
    revenue,
    profit,
    margin_percent,
    units_sold,
    revenue_contribution,
    running_percent,
    case
        when running_percent <= 80 then 'a'
        when running_percent <= 95 then 'b'
        else 'c'
    end as abc_category,
    case
        when running_percent <= 80 then 'a - top revenue (80%)'
        when running_percent <= 95 then 'b - medium revenue (15%)'
        else 'c - low revenue (5%)'
    end as abc_description,
    case
        when revenue_contribution >= 10 then 'high impact'
        when revenue_contribution >= 5 then 'medium impact'
        else 'low impact'
    end as impact_level,
    dense_rank() over(partition by 
        case
            when running_percent <= 80 then 'a'
            when running_percent <= 95 then 'b'
            else 'c'
        end
        order by revenue desc
    ) as category_rank
from ranked_products
order by running_percent;

-- --------------------------------------------------24
create view vw_inventory_health as
with product_metrics as (
    select
        p.prod_id,
        p.prod_name,
        p.category,
        p.price,
        p.stock as current_stock,
        round(p.price * p.stock, 2) as inventory_value,
        coalesce(sum(oi.quantity), 0) as units_sold,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as revenue,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as profit,
        max(o.order_date) as last_sale_date,
        datediff(curdate(), max(o.order_date)) as days_since_last_sale
    from products p
    left join order_items oi on p.prod_id = oi.prod_id
    left join orders o on oi.order_id = o.order_id
        and o.order_status in ('delivered', 'shipped')
    group by p.prod_id, p.prod_name, p.category, p.price, p.stock
),
return_metrics as (
    select
        r.prod_id,
        coalesce(sum(r.quantity), 0) as returned_units,
        coalesce(round(sum(r.quantity * oi.selling_price), 2), 0) as return_revenue
    from returns r
    left join order_items oi on r.order_id = oi.order_id and r.prod_id = oi.prod_id
    group by r.prod_id
),
inventory_turnover as (
    select
        prod_id,
        case
            when current_stock = 0 and units_sold > 0 then units_sold
            when current_stock = 0 and units_sold = 0 then 0
            else round(units_sold / current_stock, 2)
        end as turnover_ratio,
        case
            when units_sold = 0 then 0
            else round(current_stock / (units_sold / 30.0), 0)
        end as days_of_inventory
    from product_metrics
),
health_calc as (
    select
        pm.prod_id,
        pm.prod_name,
        pm.category,
        pm.price,
        pm.current_stock,
        pm.inventory_value,
        pm.units_sold,
        pm.revenue,
        pm.profit,
        pm.days_since_last_sale,
        coalesce(rm.returned_units, 0) as returned_units,
        coalesce(it.turnover_ratio, 0) as turnover_ratio,
        coalesce(it.days_of_inventory, 0) as days_of_inventory,
        case
            when pm.current_stock = 0 then 0
            else round(pm.units_sold / pm.current_stock, 2)
        end as turnover,
        case
            when pm.days_since_last_sale = 0 then 100
            else round(100 - (pm.days_since_last_sale / 3.0), 2)
        end as recency_score,
        case
            when coalesce(rm.returned_units, 0) = 0 then 50
            else round(50 - (coalesce(rm.returned_units, 0) * 2.0), 2)
        end as return_score,
        round(
            (case when pm.current_stock = 0 then 0 else pm.units_sold / pm.current_stock end) * 2 +
            (case when pm.days_since_last_sale = 0 then 100 else 100 - (pm.days_since_last_sale / 3.0) end) +
            (case when coalesce(rm.returned_units, 0) = 0 then 50 else 50 - (coalesce(rm.returned_units, 0) * 2.0) end),
        2) as health_score
    from product_metrics pm
    left join return_metrics rm on pm.prod_id = rm.prod_id
    left join inventory_turnover it on pm.prod_id = it.prod_id
)
select
    prod_id,
    prod_name,
    category,
    price,
    current_stock,
    inventory_value,
    units_sold,
    revenue,
    profit,
    days_since_last_sale,
    returned_units,
    round(100.0 * coalesce(returned_units, 0) / nullif(units_sold, 0), 2) as return_percent,
    turnover_ratio,
    days_of_inventory,
    case
        when current_stock = 0 and units_sold = 0 then 'no stock'
        when current_stock = 0 and units_sold > 0 then 'critical - reorder'
        when days_since_last_sale >= 180 then 'dead stock'
        when days_since_last_sale >= 90 then 'slow moving'
        when days_since_last_sale >= 30 then 'normal'
        else 'healthy'
    end as stock_health,
    case
        when current_stock > 100 and units_sold = 0 then 'overstocked'
        when current_stock > 100 and days_since_last_sale > 60 then 'overstocked'
        when current_stock = 0 and units_sold > 0 then 'reorder'
        when current_stock <= 10 and units_sold > 0 then 'critical reorder'
        when current_stock <= 25 and units_sold > 0 then 'low stock'
        when current_stock > 100 and units_sold > 0 then 'healthy stock'
        else 'normal'
    end as stock_status,
    case
        when current_stock = 0 then 0
        else round(100.0 * units_sold / (units_sold + current_stock), 2)
    end as sell_through_rate,
    health_score,
    case
        when (case when current_stock = 0 then 0 else units_sold / current_stock end) * 2 >= 6
            and days_since_last_sale < 30 then 'excellent health'
        when health_score >= 70 then 'good health'
        when health_score >= 50 then 'average health'
        when health_score >= 30 then 'poor health'
        else 'critical health'
    end as health_status
from health_calc
order by health_score desc;

-- -------------------------------------------------------------25
create view vw_executive_scorecard as
with revenue_metrics as (
    select
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as total_revenue,
        coalesce(round(sum(oi.quantity * oi.selling_price) - 
                  coalesce(sum(r.quantity * oi.selling_price), 0) - 
                  coalesce(sum(case when pm.payment_status = 'refunded' then pm.amount else 0 end), 0), 2), 0) as net_revenue,
        coalesce(round(sum(oi.quantity * p.cost_price), 2), 0) as total_cost,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0) as gross_profit,
        count(distinct o.order_id) as total_orders,
        count(distinct c.cust_id) as total_customers
    from orders o
    left join customers c on o.cust_id = c.cust_id
    left join order_items oi on o.order_id = oi.order_id
    left join products p on oi.prod_id = p.prod_id
    left join returns r on oi.order_id = r.order_id and oi.prod_id = r.prod_id
    left join payments pm on o.order_id = pm.order_id
    where o.order_status in ('delivered', 'shipped')
),
return_metrics as (
    select
        count(distinct r.return_id) as total_returns,
        coalesce(round(sum(r.quantity * oi.selling_price), 2), 0) as return_revenue
    from returns r
    left join order_items oi on r.order_id = oi.order_id and r.prod_id = oi.prod_id
),
refund_metrics as (
    select
        count(distinct pm.payment_id) as total_refunds,
        coalesce(round(sum(pm.amount), 2), 0) as refund_amount
    from payments pm
    where pm.payment_status = 'refunded'
),
review_metrics as (
    select
        round(avg(rating), 2) as avg_rating
    from reviews
),
top_product as (
    select p.prod_name
    from products p
    left join order_items oi on p.prod_id = oi.prod_id
    left join orders o on oi.order_id = o.order_id and o.order_status in ('delivered', 'shipped')
    group by p.prod_name
    order by sum(oi.quantity * oi.selling_price) desc
    limit 1
),
top_category as (
    select p.category
    from products p
    left join order_items oi on p.prod_id = oi.prod_id
    left join orders o on oi.order_id = o.order_id and o.order_status in ('delivered', 'shipped')
    group by p.category
    order by sum(oi.quantity * oi.selling_price) desc
    limit 1
),
top_city as (
    select c.city
    from customers c
    left join orders o on c.cust_id = o.cust_id and o.order_status in ('delivered', 'shipped')
    left join order_items oi on o.order_id = oi.order_id
    group by c.city
    order by sum(oi.quantity * oi.selling_price) desc
    limit 1
),
top_campaign as (
    select mc.campaign_name
    from marketing_campaigns mc
    left join customer_campaigns cc on mc.campaign_id = cc.campaign_id
    left join customers c on cc.cust_id = c.cust_id
    left join orders o on c.cust_id = o.cust_id and o.order_status in ('delivered', 'shipped')
    left join order_items oi on o.order_id = oi.order_id
    group by mc.campaign_name
    order by sum(oi.quantity * oi.selling_price) desc
    limit 1
),
clv_metrics as (
    select
        round(sum(oi.quantity * oi.selling_price) / nullif(count(distinct c.cust_id), 0), 2) as avg_clv,
        round(sum(oi.quantity * oi.selling_price) / nullif(count(distinct o.order_id), 0), 2) as avg_order_value
    from orders o
    left join customers c on o.cust_id = c.cust_id
    left join order_items oi on o.order_id = oi.order_id
    where o.order_status in ('delivered', 'shipped')
),
monthly_growth as (
    select
        round(100.0 * (sum(case when month(order_date) = month(curdate()) then oi.quantity * oi.selling_price else 0 end) -
                      sum(case when month(order_date) = month(date_sub(curdate(), interval 1 month)) then oi.quantity * oi.selling_price else 0 end)) /
              nullif(sum(case when month(order_date) = month(date_sub(curdate(), interval 1 month)) then oi.quantity * oi.selling_price else 0 end), 0), 2) as monthly_growth
    from orders o
    left join order_items oi on o.order_id = oi.order_id
    where o.order_status in ('delivered', 'shipped')
      and order_date >= date_sub(curdate(), interval 2 month)
),
quarterly_growth as (
    select
        round(100.0 * (sum(case when quarter(order_date) = quarter(curdate()) then oi.quantity * oi.selling_price else 0 end) -
                      sum(case when quarter(order_date) = quarter(date_sub(curdate(), interval 1 quarter)) then oi.quantity * oi.selling_price else 0 end)) /
              nullif(sum(case when quarter(order_date) = quarter(date_sub(curdate(), interval 1 quarter)) then oi.quantity * oi.selling_price else 0 end), 0), 2) as quarterly_growth
    from orders o
    left join order_items oi on o.order_id = oi.order_id
    where o.order_status in ('delivered', 'shipped')
      and order_date >= date_sub(curdate(), interval 2 quarter)
),
ytd_revenue as (
    select
        round(sum(oi.quantity * oi.selling_price), 2) as ytd_revenue
    from orders o
    left join order_items oi on o.order_id = oi.order_id
    where o.order_status in ('delivered', 'shipped')
      and year(order_date) = year(curdate())
),
revenue_target as (
    select round(100.0 * (select ytd_revenue from ytd_revenue) / 10000000, 2) as revenue_target_percent
),
health_score as (
    select
        round(
            (case when (select total_revenue from revenue_metrics) > 10000000 then 25 else (select total_revenue from revenue_metrics) / 10000000 * 25 end) +
            (case when (select total_customers from revenue_metrics) > 2000 then 20 else (select total_customers from revenue_metrics) / 2000 * 20 end) +
            (case when (select gross_profit from revenue_metrics) / nullif((select total_revenue from revenue_metrics), 0) > 0.30 then 20 else 10 end) +
            (case when (select avg_rating from review_metrics) >= 4.0 then 20 else 10 end) +
            (case when (select total_returns from return_metrics) / nullif((select total_orders from revenue_metrics), 0) < 0.05 then 15 else 5 end),
        2) as health_score
)
select
    rm.total_revenue,
    rm.net_revenue,
    rm.total_orders,
    rm.total_customers,
    rm.gross_profit,
    round(100.0 * rm.gross_profit / nullif(rm.total_revenue, 0), 2) as profit_margin,
    clv.avg_order_value,
    clv.avg_clv as customer_lifetime_value,
    round(100.0 * rt.total_returns / nullif(rm.total_orders, 0), 2) as return_rate,
    round(100.0 * rf.total_refunds / nullif(rm.total_orders, 0), 2) as refund_rate,
    rv.avg_rating,
    tp.prod_name as top_product,
    tc.category as top_category,
    tcity.city as top_city,
    tcam.campaign_name as best_campaign,
    mg.monthly_growth,
    qg.quarterly_growth,
    ytd.ytd_revenue,
    rtg.revenue_target_percent,
    hs.health_score,
    case
        when hs.health_score >= 90 then 'excellent'
        when hs.health_score >= 75 then 'good'
        when hs.health_score >= 60 then 'average'
        when hs.health_score >= 40 then 'below average'
        else 'critical'
    end as business_status
from revenue_metrics rm
cross join return_metrics rt
cross join refund_metrics rf
cross join review_metrics rv
cross join clv_metrics clv
cross join top_product tp
cross join top_category tc
cross join top_city tcity
cross join top_campaign tcam
cross join monthly_growth mg
cross join quarterly_growth qg
cross join ytd_revenue ytd
cross join revenue_target rtg
cross join health_score hs;
