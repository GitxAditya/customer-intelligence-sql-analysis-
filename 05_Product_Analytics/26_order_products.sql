use customer_intelligence_db;

-- ------------------------------------------------------------Ques 26
with order_products as(
	select
        o.order_id,
        oi.prod_id,
        p.prod_name
	from orders o 
    inner join order_items oi on oi.order_id = o.order_id
    inner join products p on oi.prod_id = p.prod_id
    where o.order_status in ('Delivered', 'Shipped')
    group by  o.order_id, oi.prod_id, p.prod_name
),
product_pairs as (
	select
		a.prod_id as prod_a_id ,
        b.prod_id as prod_b_id,
		a.prod_name as product_a,
        b.prod_name as product_b,
        a.order_id
	from order_products a
    inner join order_products b
		on a.order_id = b.order_id
        and a.prod_id < b.prod_id
	group by prod_a_id, prod_b_id, product_a, product_b, a.order_id
),
pair_counts as(
	select
		product_a,
        product_b,
		prod_a_id,        
        prod_b_id,         
        count(*) as orders_together
	from product_pairs
    group by product_a, product_b, prod_a_id, prod_b_id
),
total_orders as (
	select
		prod_id,
        count(distinct order_id) as total_orders
	from order_products 
    group by prod_id
)
select
	pc.product_a,
	pc.product_b,
    pc.orders_together,
    round(100* pc.orders_together/ nullif(t1.total_orders,0),2) as confidence_a_to_b,
    round(100* pc.orders_together/ nullif(t2.total_orders,0),2) as confidence_b_to_a,
    rank() over(order by pc.orders_together desc) as pair_rank
from pair_counts pc
join total_orders t1 on t1.prod_id = pc.prod_a_id 
join total_orders t2 on t2.prod_id = pc.prod_b_id
order by pair_rank
limit 20