use customer_intelligence_db;

-- --------------------------------------------------------------Ques 30
 with product_revenue as (
    select
        p.prod_id,
        p.prod_name,
        p.category,
        p.brand,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue
	from products p
    left join order_items oi on oi.prod_id = p.prod_id
    left join orders o on o.order_id = oi.order_id
		and o.order_status IN ('Delivered', 'Shipped')
    left join payments pm on o.order_id = pm.order_id
		and pm.payment_status = 'Success'
	group by p.prod_id, p.prod_name, p.category, p.brand, p.stock
),
revenue_ranked as(
select
	prod_id,
    prod_name,
    category,
    brand,
    revenue,
    round(100* revenue/ sum(revenue) over(),2) as revenue_percent,
    round(100* sum(revenue) over(order by revenue desc)/ sum(revenue) over(),2) as cumulative_percent,
    row_number() over(order by revenue desc) as product_rank
from product_revenue
where revenue > 0
)
select
	product_rank,
    prod_name,
    category,
    brand,
    revenue,
    revenue_percent,
    cumulative_percent,
    case
        when cumulative_percent <= 80 then 'A - Top Revenue'
        when cumulative_percent <= 95 then 'B - Medium Revenue'
        else 'C - Low Revenue'
    end as abc_category,
    case
        when cumulative_percent <= 80 then 'High Priority'
        when cumulative_percent <= 95 then 'Medium Priority'
        else 'Low Priority'
    end as priority
from revenue_ranked
order by product_rank;